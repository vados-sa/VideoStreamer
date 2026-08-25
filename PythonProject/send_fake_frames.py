import asyncio

import websockets
import cv2 as cv

URL = "ws://127.0.0.1:8000/ws/videostream"

async def send_frames():
    cam = cv.VideoCapture(0)
    async with websockets.connect(URL) as ws:
        for i in range(100):
            await ws.send(cv.imencode(".jpg", cam.read()[1], [cv.IMWRITE_JPEG_QUALITY, 60])[1].tobytes())
    cam.release()
    print(i)

asyncio.run(send_frames())
