# Auto-Port Development Server - Always Fresh Content
Write-Host "🚀 Auto-Port Development Server - Always Fresh Content" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Function to find an available port
function Find-AvailablePort {
    param(
        [int]$StartPort = 3000,
        [int]$EndPort = 9000
    )
    
    for ($port = $StartPort; $port -le $EndPort; $port++) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("localhost", $port)
            $tcp.Close()
            # Port is in use, try next
        } catch {
            # Port is available
            return $port
        }
    }
    return $null
}

# Function to stop any existing servers on common ports
function Stop-ExistingServers {
    Write-Host "🔄 Stopping any existing servers..." -ForegroundColor Yellow
    
    $commonPorts = @(8000, 8080, 3000, 4000, 5000, 6000, 7000)
    
    foreach ($port in $commonPorts) {
        try {
            $processes = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | 
                        Where-Object {$_.State -eq "Listen"} | 
                        ForEach-Object {Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue}
            
            foreach ($process in $processes) {
                if ($process.ProcessName -eq "python" -or $process.ProcessName -eq "python3") {
                    Write-Host "🛑 Stopping server on port $port (PID: $($process.Id))" -ForegroundColor Red
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {
            # Ignore errors
        }
    }
    
    # Wait a moment for processes to stop
    Start-Sleep -Seconds 2
    Write-Host "✅ Server cleanup complete" -ForegroundColor Green
    Write-Host ""
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Stop existing servers
Stop-ExistingServers

# Find an available port
Write-Host "🔍 Finding available port..." -ForegroundColor Yellow
$port = Find-AvailablePort

if (-not $port) {
    Write-Host "❌ Error: No available ports found in range 3000-9000" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found available port: $port" -ForegroundColor Green
Write-Host ""

# Check git status
Write-Host "📊 Checking git status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "🌐 Starting development server..." -ForegroundColor Green
Write-Host "Your PWA will be available at: http://localhost:$port" -ForegroundColor White
Write-Host ""

Write-Host "💡 AUTO-PORT REFRESH SYSTEM:" -ForegroundColor Magenta
Write-Host "=============================" -ForegroundColor Magenta
Write-Host "• Every time you run this script, it will use a NEW port" -ForegroundColor White
Write-Host "• This ensures you always see the latest changes" -ForegroundColor White
Write-Host "• No more manual port switching needed!" -ForegroundColor White
Write-Host ""

Write-Host "💡 HOW TO MAKE LIVE CHANGES (Desktop Browser):" -ForegroundColor Magenta
Write-Host "1. Open your browser to http://localhost:$port" -ForegroundColor White
Write-Host "2. Open DevTools (F12 or Ctrl+Shift+I)" -ForegroundColor White
Write-Host "3. In Elements tab: Right-click elements to edit HTML/CSS" -ForegroundColor White
Write-Host "4. In Console tab: Test JavaScript changes" -ForegroundColor White
Write-Host "5. In Sources tab: Edit files directly (changes are temporary)" -ForegroundColor White
Write-Host ""

Write-Host "📱 MOBILE DEVICE TESTING:" -ForegroundColor Magenta
Write-Host "=========================" -ForegroundColor Magenta
Write-Host "🍎 iPhone Safari: http://localhost:$port" -ForegroundColor White
Write-Host "🤖 Android Chrome: http://localhost:$port" -ForegroundColor White
Write-Host ""

Write-Host "🔄 TO REFRESH AND SEE NEW CHANGES:" -ForegroundColor Cyan
Write-Host "1. Stop this server (Ctrl+C)" -ForegroundColor White
Write-Host "2. Run this script again: .\dev-auto-port.ps1" -ForegroundColor White
Write-Host "3. It will automatically use a NEW port" -ForegroundColor White
Write-Host "4. Open the new URL in your browser" -ForegroundColor White
Write-Host ""

Write-Host "📝 When ready to save changes:" -ForegroundColor Green
Write-Host "- Copy your changes from DevTools to the actual files in your project directory." -ForegroundColor White
Write-Host "- Run: git add . && git commit -m \"Your message\" && git push origin main" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Starting server on port $port..." -ForegroundColor Green
Write-Host "🌐 URL: http://localhost:$port" -ForegroundColor Cyan
Write-Host "🔄 To refresh: Stop server (Ctrl+C) and run this script again" -ForegroundColor Yellow
Write-Host ""

try {
    python -m http.server $port
} catch {
    Write-Host "❌ Python not found, trying python3..." -ForegroundColor Red
    try {
        python3 -m http.server $port
    } catch {
        Write-Host "❌ No Python found. Please install Python or use WSL2." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
