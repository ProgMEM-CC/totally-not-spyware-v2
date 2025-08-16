#!/usr/bin/env bash
set -euo pipefail

# Arguments: [IP] [PASSWORD]
IP="${1:-}"
PASS="${2:-}"
if [[ -z "$IP" ]]; then
  # Try to detect local subnet and prompt for last octet
  if ip route 2>/dev/null | grep -q 'src'; then
    CAND=$(ip route get 1 | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
  else
    CAND=$(ifconfig 2>/dev/null | awk '/inet / && $2!="127.0.0.1" {print $2; exit}')
  fi
  if [[ -n "$CAND" ]]; then
    PREF=$(echo "$CAND" | awk -F. '{print $1"."$2"."$3}')
    read -rp "Enter iPhone last octet (prefix $PREF) or full IP: " LAST
    if [[ "$LAST" =~ ^[0-9]+$ ]]; then IP="$PREF.$LAST"; else IP="$LAST"; fi
  fi
  if [[ -z "$IP" ]]; then read -rp "Enter iPhone IP (e.g. 192.168.1.23): " IP; fi
fi

# Ask password (default alpine) if not supplied
if [[ -z "${PASS}" ]]; then
  read -rsp "Enter root password (press Enter for 'alpine'): " PASS; echo
  [[ -z "${PASS}" ]] && PASS='alpine'
fi

# If sshpass is available, use it for non-interactive password; else fall back to interactive ssh
if command -v sshpass >/dev/null 2>&1; then
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@"$IP" 'sh -s' <<'SH'
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
else
  echo "sshpass not found; using interactive ssh (you will be prompted)."
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
fi

echo "Done."

