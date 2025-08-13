#!/usr/bin/env python3
import sys, json, subprocess, ctypes, os

def read_message():
    raw_len = sys.stdin.buffer.read(4)
    if len(raw_len) == 0:
        return None
    msg_len = int.from_bytes(raw_len, byteorder='little')
    data = sys.stdin.buffer.read(msg_len)
    return json.loads(data.decode('utf-8'))

def send_message(message):
    encoded = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(len(encoded).to_bytes(4, byteorder='little'))
    sys.stdout.buffer.write(encoded)
    sys.stdout.flush()

def kill_http_servers():
    try:
        # Windows-specific kill using tasklist + taskkill
        subprocess.run(['powershell','-NoProfile','-Command',
            "$p=Get-CimInstance Win32_Process | Where-Object { ($_.Name -match 'python' -or $_.Name -match 'python3') -and $_.CommandLine -match 'http.server' }; foreach($x in $p){ try{ Stop-Process -Id $x.ProcessId -Force -ErrorAction SilentlyContinue } catch{} }"],
            check=False)
    except Exception:
        pass

def start_server(port):
    # Start detached
    DETACHED_PROCESS = 0x00000008
    subprocess.Popen(['python','-m','http.server',str(port),'--bind','127.0.0.1'],
        creationflags=DETACHED_PROCESS, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    while True:
        msg = read_message()
        if msg is None: break
        action = msg.get('action')
        if action == 'restart':
            port = msg.get('port','8080')
            kill_http_servers()
            start_server(port)
            send_message({'ok': True, 'port': port})
        else:
            send_message({'ok': False, 'error': 'unknown action'})

if __name__ == '__main__':
    main()


