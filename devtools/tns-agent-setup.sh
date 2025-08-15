#!/usr/bin/env bash
set -euo pipefail

IP="${1:-}"
if [[ -z "$IP" ]]; then
  read -rp "Enter iPhone IP (e.g. 192.168.1.23): " IP
fi

ssh -o StrictHostKeyChecking=no root@"$IP" 'sh -s' <<'SH'
set -e
PM=apt; command -v apt >/dev/null 2>&1 || PM=apt-get
$PM update || true
$PM install -y curl netcat || true

[ -f /usr/bin/tnsjb-agent ] && { chmod 0755 /usr/bin/tnsjb-agent; chown root:wheel /usr/bin/tnsjb-agent || true; }
[ -f /Library/LaunchDaemons/com.tns.agent.plist ] && { chmod 0644 /Library/LaunchDaemons/com.tns.agent.plist; chown root:wheel /Library/LaunchDaemons/com.tns.agent.plist || true; }

launchctl bootout system/com.tns.agent >/dev/null 2>&1 || true
if [ -f /Library/LaunchDaemons/com.tns.agent.plist ]; then
  launchctl bootstrap system /Library/LaunchDaemons/com.tns.agent.plist 2>/dev/null || launchctl load -w /Library/LaunchDaemons/com.tns.agent.plist
  launchctl enable system/com.tns.agent >/dev/null 2>&1 || true
  launchctl kickstart -k system/com.tns.agent >/dev/null 2>&1 || true
fi

echo '--- PING ---'
curl -fsS -m 3 http://127.0.0.1:17385/ping || echo 'PING FAIL'
echo '--- PS ---'; ps ax | grep -v grep | grep tnsjb-agent || true
echo '--- PORT ---'; netstat -an | grep 17385 || true
SH

echo "Done."

