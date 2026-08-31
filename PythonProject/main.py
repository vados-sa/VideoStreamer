import asyncio
import logging
import uvicorn
import cv2 as cv
import numpy as np
from fastapi import FastAPI, WebSocket
import httpx
from httpx import TimeoutException, ConnectError

from starlette.websockets import WebSocketDisconnect, WebSocketState

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("videostreamer")
app = FastAPI()

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
    try:
        while True:
            msg = await websocket.receive()

            if msg["type"] == "websocket.disconnect":
                log.info("Client disconnected")
                break

            if msg.get("bytes"):
                data = msg["bytes"]
                frame = cv.imdecode(np.frombuffer(data, np.uint8), cv.IMREAD_COLOR)
                if frame is None:
                    log.warning(f"bad frame, {len(data)} bytes")
                    continue
                log.info(f"Got frame: {frame.shape}")
            elif msg.get("text"):
                log.info("Text message:", msg["text"])

    except WebSocketDisconnect:
        log.info("Client disconnected")
    finally:
        #cv.destroyAllWindows()
        sender_task.cancel()
        await asyncio.gather(sender_task, return_exceptions=True)
        log.info("Application Closing!")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) # to run: uv run python main.py

