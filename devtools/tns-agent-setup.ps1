Param([string]$Ip)

# Autofill helper: detect local subnet and ask only for last octet
if (-not $Ip -or $Ip.Trim().Length -eq 0) {
  try {
    $cand = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' } | Select-Object -First 1).IPAddress
  } catch { $cand = $null }
  $prefix = $null
  if ($cand) { $prefix = ($cand -split '\.')[0..2] -join '.' }
  if ($prefix) {
    $last = Read-Host "Enter iPhone last octet (prefix $prefix) or full IP"
    if ($last -match '^\d+$') { $Ip = "$prefix.$last" } else { $Ip = $last }
  }
  if (-not $Ip -or $Ip.Trim().Length -eq 0) { $Ip = Read-Host "Enter iPhone IP (e.g. 192.168.1.23)" }
}

$remote = @'
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
'@

Write-Host "Connecting to root@$Ip (password default is 'alpine')" -ForegroundColor Cyan
$remote | ssh -o StrictHostKeyChecking=no "root@$Ip" 'sh -s'

