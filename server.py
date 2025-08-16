import asyncio
import aiohttp
import aiofiles
from aiohttp import web
from multidict import CIMultiDict
import os
import uuid
import tempfile
import shutil
import zipfile
import json
import hashlib
import datetime
import secrets

Clients = {}

def clear_console() -> None:
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear')

def Log(message, client):
    if client in Clients:
        print(message)
        if not os.path.exists("Logs"):
            os.mkdir("Logs")
        with open("Logs/" + str(Clients[client]) + ".log", "a") as f:
            f.write(message + "\n")
    
def ClearLogs():
    for log in os.listdir("Logs"):
        os.remove("Logs/" + log)

async def handle(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/html',
        }
    )
    async with aiofiles.open('index.html', mode='r') as f:
        html_content = await f.read()
    return web.Response(text=html_content, headers=headers)

async def utils(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('utils.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def int64(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('int64.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def helper(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('helper.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def pwn(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('pwn.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def stages(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('stages.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def offsets(request):
    headers = CIMultiDict(
        {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Content-Type': 'text/javascript',
        }
    )
    async with aiofiles.open('offsets.js', mode='r') as f:
        js_content = await f.read()
    return web.Response(text=js_content, headers=headers)

async def wshandler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)
    Clients[ws] = uuid.uuid4()
    clear_console()
    print("UUID: " + str(Clients[ws]))
    try:
        async for msg in ws:
            if msg.type == aiohttp.WSMsgType.TEXT:
                Log(f"{msg.data}", ws)
                await ws.send_str(f"copy_that")
            elif msg.type == aiohttp.WSMsgType.ERROR:
                print(f"WebSocket closed with exception: {ws.exception()}")
    except ConnectionResetError:
        pass
    print("WebKit Crash")
    return ws

async def ffmpeg_available() -> bool:
    try:
        proc = await asyncio.create_subprocess_exec(
            'ffmpeg', '-version', stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False

async def transcode_health(request: web.Request) -> web.Response:
    ok = await ffmpeg_available()
    return web.json_response({'ffmpeg': ok})

async def transcode_webp(request: web.Request) -> web.StreamResponse:
    # CORS
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'no-store'
    }
    if request.method == 'OPTIONS':
        return web.Response(status=204, headers=headers)
    if not await ffmpeg_available():
        return web.json_response({'error': 'ffmpeg not available on server'}, status=501, headers=headers)
    reader = await request.multipart()
    field = await reader.next()
    if not field or field.name != 'file':
        return web.json_response({'error': 'no file field'}, status=400, headers=headers)
    tmpdir = tempfile.mkdtemp(prefix='tns_transcode_')
    try:
        src_path = os.path.join(tmpdir, 'input')
        # Write upload to disk
        async with aiofiles.open(src_path, 'wb') as f:
            while True:
                chunk = await field.read_chunk()
                if not chunk:
                    break
                await f.write(chunk)
        # Prepare outputs
        out_small = os.path.join(tmpdir, 'snapshot-small.webp')
        out_lossless = os.path.join(tmpdir, 'snapshot-lossless.webp')
        # Small
        cmd_small = [
            'ffmpeg','-y','-i',src_path,
            '-vf','fps=12,scale=540:-1:flags=lanczos,setsar=1',
            '-c:v','libwebp','-q:v','60','-loop','0','-an', out_small
        ]
        # Lossless
        cmd_loss = [
            'ffmpeg','-y','-i',src_path,
            '-vf','fps=8,scale=480:-1:flags=lanczos,setsar=1',
            '-c:v','libwebp','-lossless','1','-compression_level','6','-loop','0','-an', out_lossless
        ]
        for cmd in (cmd_small, cmd_loss):
            proc = await asyncio.create_subprocess_exec(*cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            _out, _err = await proc.communicate()
            if proc.returncode != 0:
                # Continue; maybe one variant still succeeded
                pass
        zip_path = os.path.join(tmpdir, 'transcoded.zip')
        with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
            if os.path.exists(out_small):
                z.write(out_small, 'snapshot-small.webp')
            if os.path.exists(out_lossless):
                z.write(out_lossless, 'snapshot-lossless.webp')
        if not os.path.exists(zip_path):
            return web.json_response({'error': 'transcode failed'}, status=500, headers=headers)
        resp = web.StreamResponse(status=200, reason='OK', headers={**headers, 'Content-Type': 'application/zip', 'Content-Disposition': 'attachment; filename="transcoded.zip"'})
        await resp.prepare(request)
        async with aiofiles.open(zip_path, 'rb') as f:
            chunk = await f.read(1024*1024)
            while chunk:
                await resp.write(chunk)
                chunk = await f.read(1024*1024)
        await resp.write_eof()
        return resp
    finally:
        try:
            shutil.rmtree(tmpdir)
        except Exception:
            pass

# ---- Privacy-preserving telemetry collection --------------------------------
_SALT_PATH = '.telemetry_salt'
_TELEMETRY_DIR = 'telemetry'
_TELEMETRY_FILE = os.path.join(_TELEMETRY_DIR, 'analytics.ndjson')

def _get_salt() -> bytes:
    try:
        if os.path.exists(_SALT_PATH):
            with open(_SALT_PATH, 'rb') as f:
                return f.read()
        salt = secrets.token_bytes(16)
        with open(_SALT_PATH, 'wb') as f:
            f.write(salt)
        return salt
    except Exception:
        return b'fixed-salt'

async def _geoip_coarse(ip: str) -> dict:
    # Coarse geolocation using ipapi.co (best-effort, optional)
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f'https://ipapi.co/{ip}/json/', timeout=3) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return {
                        'country': data.get('country_name'),
                        'region': data.get('region'),
                        'city': data.get('city'),
                        'approx_loc': data.get('latitude') and data.get('longitude') and f"{round(data.get('latitude',0),2)},{round(data.get('longitude',0),2)}" or None,
                    }
    except Exception:
        pass
    return {}

async def collect_telemetry(request: web.Request) -> web.Response:
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'no-store'
    }
    if request.method == 'OPTIONS':
        return web.Response(status=204, headers=headers)
    try:
        payload = await request.json()
    except Exception:
        payload = {}
    # Redact/approximate IP
    ip = request.remote or ''
    salt = _get_salt()
    ip_hash = hashlib.sha256(salt + ip.encode('utf-8')).hexdigest()[:16] if ip else None
    # Optional coarse geo
    geo = await _geoip_coarse(ip) if ip else {}
    # Compose event
    event = {
        'ts': datetime.datetime.utcnow().isoformat() + 'Z',
        'event': payload.get('event'),
        'session': payload.get('session'),
        'ua': payload.get('ua'),
        'platform': payload.get('platform'),
        'viewport': payload.get('viewport'),
        'theme': payload.get('theme'),
        'page': payload.get('page'),
        'outcome': payload.get('outcome'),
        'ip_hash': ip_hash,
        'geo': geo,
    }
    try:
        os.makedirs(_TELEMETRY_DIR, exist_ok=True)
        with open(_TELEMETRY_FILE, 'a', encoding='utf-8') as f:
            f.write(json.dumps(event, ensure_ascii=False) + "\n")
    except Exception:
        pass
    return web.json_response({'ok': True}, headers=headers)

try:
    ClearLogs()
    app = web.Application()
    app.router.add_get('/', handle)
    app.router.add_get('/utils.js', utils)
    app.router.add_get('/int64.js', int64)
    app.router.add_get('/helper.js', helper)
    app.router.add_get('/pwn.js', pwn)
    app.router.add_get('/stages.js', stages)
    app.router.add_get('/offsets.js', offsets)
    app.router.add_get('/WebSocket', wshandler)
    app.router.add_route('*', '/api/transcode', transcode_webp)
    app.router.add_get('/api/health', transcode_health)
    app.router.add_route('*', '/api/collect', collect_telemetry)
    web.run_app(app, host='0.0.0.0', port=1337)
except KeyboardInterrupt:
    exit(0)