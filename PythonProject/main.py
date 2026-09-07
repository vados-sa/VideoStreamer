import asyncio
import logging
import time
import uvicorn
import cv2 as cv
import numpy as np
from fastapi import FastAPI, WebSocket
import httpx
from httpx import TimeoutException, ConnectError

from starlette.websockets import WebSocketDisconnect, WebSocketState

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("videostreamer")
app = FastAPI()

# Emit an aggregated frame-stats line at most this often (seconds).
SUMMARY_INTERVAL = 1.0


class FrameStats:
    """Per-connection accumulator for frames arriving as bare JPEG bytes.

    The iOS client sends no metadata, so everything here is derived from the
    raw payload and the decoded frame. Totals live for the whole session;
    the ``_iv`` fields reset every time a summary line is flushed.
    """

    def __init__(self):
        now = time.monotonic()
        self.session_start = now
        self.last_flush = now
        self.last_frame_ts = None
        self.last_res = None  # (h, w) most recently logged

        # session totals
        self.frames = 0
        self.bad_frames = 0
        self.total_bytes = 0

        self._reset_interval()

    def _reset_interval(self):
        self.iv_frames = 0
        self.iv_bytes = 0
        self.iv_size_min = None
        self.iv_size_max = None
        self.iv_decode_ms = 0.0
        self.iv_brightness = 0.0
        self.iv_gap_ms = 0.0
        self.iv_gap_max = 0.0
        self.iv_raw_bytes = 0  # uncompressed size (h*w*channels) for ratio

    def record(self, size, decode_ms, frame):
        now = time.monotonic()
        h, w = frame.shape[:2]
        channels = frame.shape[2] if frame.ndim == 3 else 1

        self.frames += 1
        self.total_bytes += size

        self.iv_frames += 1
        self.iv_bytes += size
        self.iv_decode_ms += decode_ms
        self.iv_brightness += float(frame.mean())
        self.iv_raw_bytes += h * w * channels
        self.iv_size_min = size if self.iv_size_min is None else min(self.iv_size_min, size)
        self.iv_size_max = size if self.iv_size_max is None else max(self.iv_size_max, size)

        if self.last_frame_ts is not None:
            gap_ms = (now - self.last_frame_ts) * 1000
            self.iv_gap_ms += gap_ms
            self.iv_gap_max = max(self.iv_gap_max, gap_ms)
        self.last_frame_ts = now

        self.last_res = (h, w)

    def due(self):
        return (
            self.iv_frames > 0
            and time.monotonic() - self.last_flush >= SUMMARY_INTERVAL
        )

    def summary_line(self):
        elapsed = time.monotonic() - self.last_flush
        n = self.iv_frames
        avg_size = self.iv_bytes / n
        fps = n / elapsed if elapsed > 0 else 0.0
        bitrate = self.iv_bytes / elapsed if elapsed > 0 else 0.0
        ratio = (self.iv_raw_bytes / self.iv_bytes) if self.iv_bytes else 0.0
        gap_avg = self.iv_gap_ms / n
        decode_avg = self.iv_decode_ms / n
        brightness = self.iv_brightness / n
        h, w = self.last_res

        line = (
            f"\n- frames={n} fps={fps:.1f} \n"
            f"- size avg={avg_size / 1024:.1f}KB \n"
            f"- min/max={self.iv_size_min / 1024:.1f}/{self.iv_size_max / 1024:.1f}KB \n"
            f"- bitrate={bitrate / 1_000_000:.2f} MB/s ratio={ratio:.0f}x | \n"
            f"- gap avg={gap_avg:.0f}ms max={self.iv_gap_max:.0f}ms decode avg={decode_avg:.1f}ms | \n"
            f"- brightness={brightness:.0f} res={w}x{h}\n"
        )
        self.last_flush = time.monotonic()
        self._reset_interval()
        return line

    def session_line(self):
        elapsed = time.monotonic() - self.session_start
        fps = self.frames / elapsed if elapsed > 0 else 0.0
        return (
            f"session ended: {self.frames} frames in {elapsed:.1f}s (avg {fps:.1f} fps), "
            f"{self.total_bytes / 1_000_000:.1f} MB total, {self.bad_frames} bad frames"
        )


@app.get("/")
async def root():
    return {"message": "Python Server"}


async def get_telemetry():
    api_url = "http://localhost:9090/telemetry"
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(api_url, timeout=5.0)
            response.raise_for_status()
            return response.json()
    except ConnectError:
        return {"status": "error", "message": "Telemetry server unavailable"}
    except TimeoutException:
        return {"status": "error", "message": "Telemetry server timed out"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


async def telemetry_loop(websocket: WebSocket):
    try:
        while True:
            telemetry = await get_telemetry()
            if websocket.client_state != WebSocketState.CONNECTED:
                break
            await websocket.send_json({"type": "telemetry", "data": telemetry})  # send telemetry to IOS
            await asyncio.sleep(2)
    except asyncio.CancelledError:
        pass
    except Exception as e:
        log.warning(f"telemetry_loop stopped: {e}")


@app.websocket("/ws/videostream")
async def ws_videostream(websocket: WebSocket):
    await websocket.accept()
    log.info("WS accepted")
    sender_task = asyncio.create_task(telemetry_loop(websocket))
    stats = FrameStats()
    try:
        while True:
            msg = await websocket.receive()

            if msg["type"] == "websocket.disconnect":
                log.info("Client disconnected")
                break

            if msg.get("bytes"):
                data = msg["bytes"]
                size = len(data)

                decode_start = time.monotonic()
                frame = cv.imdecode(np.frombuffer(data, np.uint8), cv.IMREAD_COLOR)
                decode_ms = (time.monotonic() - decode_start) * 1000

                if frame is None:
                    stats.bad_frames += 1
                    log.warning(f"bad frame, {size} bytes")
                    continue

                first_frame = stats.frames == 0
                prev_res = stats.last_res
                stats.record(size, decode_ms, frame)
                h, w = frame.shape[:2]

                if first_frame:
                    log.info(f"first frame: {w}x{h}, {size / 1024:.1f}KB, decoded in {decode_ms:.1f}ms")
                elif prev_res is not None and prev_res != (h, w):
                    ph, pw = prev_res
                    log.info(f"resolution changed: {pw}x{ph} -> {w}x{h}")

                if stats.due():
                    log.info(stats.summary_line())
            elif msg.get("text"):
                log.info("Text message: %s", msg["text"])

    except WebSocketDisconnect:
        log.info("Client disconnected")
    finally:
        #cv.destroyAllWindows()
        sender_task.cancel()
        await asyncio.gather(sender_task, return_exceptions=True)
        if stats.frames or stats.bad_frames:
            log.info(stats.session_line())
        log.info("Application Closing!")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) # to run: uv run python main.py

