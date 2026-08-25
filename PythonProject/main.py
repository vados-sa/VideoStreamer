import asyncio
import pathlib
import cv2 as cv
import numpy as np
from fastapi import FastAPI, WebSocket
import httpx
from httpx import TimeoutException, ConnectError
import ssl

from starlette.websockets import WebSocketDisconnect

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
    while True:
        telemetry = await get_telemetry()
        await websocket.send_json({"type": "telemetry", "data": telemetry})  # send telemetry to IOS
        await asyncio.sleep(2)


@app.websocket("/ws/videostream")
async def ws_videostream(websocket: WebSocket):
    await websocket.accept()
    print("WS accepted")
    # sender_task = asyncio.create_task(telemetry_loop(websocket))
    try:
        while True:
            msg = await websocket.receive()
            print("received:", msg)
            #data = await websocket.receive_bytes()
            #frame = cv.imdecode(np.frombuffer(data, np.uint8), cv.IMREAD_COLOR)
            #if frame is None:
             #   print(f"bad frame, {len(data)} bytes")
              #  continue
            #print(frame.shape)
    except WebSocketDisconnect:
        print("Client disconnected")
    finally:
        #cv.destroyAllWindows()
        print("Application Closing!")

# uv run fastapi dev
