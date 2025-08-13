import asyncio
import websockets
import json
import uuid
from datetime import datetime

clients = {}

async def websocket_handler(websocket):
    path = websocket.path
    if path == "/WebSocket":
        client_id = str(uuid.uuid4())
        clients[client_id] = websocket
        print(f"[{datetime.now().strftime('%H:%M:%S')}] WebSocket client connected: {client_id}")
        
        try:
            async for message in websocket:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Received: {message}")
                
                if message == "totally-not-spyware-v2":
                    await websocket.send("copy_that")
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent: copy_that")
                
                # Handle exploit messages
                if "exploit" in message.lower():
                    await websocket.send("exploit_initiated")
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Exploit initiated for client: {client_id}")
                
        except websockets.exceptions.ConnectionClosed:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] WebSocket client disconnected: {client_id}")
        finally:
            if client_id in clients:
                del clients[client_id]

async def main():
    print("Starting WebSocket server on ws://localhost:8081")
    print("PWA should connect to ws://localhost:8081/WebSocket")
    
    async with websockets.serve(websocket_handler, "localhost", 8081):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
