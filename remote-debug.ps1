# Remote Debugging - iPhone Safari to Windows
Write-Host "🔗 Remote Debugging - iPhone Safari to Windows" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 iPhone Setup:" -ForegroundColor Yellow
Write-Host "1. Go to Settings → Safari → Advanced" -ForegroundColor White
Write-Host "2. Enable 'Web Inspector'" -ForegroundColor White
Write-Host "3. Make sure iPhone and PC are on same WiFi" -ForegroundColor White
Write-Host ""

Write-Host "💻 Windows Setup:" -ForegroundColor Yellow
Write-Host "1. Install Chrome or Edge (if not already)" -ForegroundColor White
Write-Host "2. Make sure ngrok is installed" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Starting ngrok tunnel..." -ForegroundColor Green
Write-Host "This will give you a public URL for your iPhone" -ForegroundColor White
Write-Host ""

Write-Host "📋 After ngrok starts:" -ForegroundColor Magenta
Write-Host "1. Copy the ngrok URL (e.g., https://abc123.ngrok.io)" -ForegroundColor White
Write-Host "2. Open Safari on iPhone and go to that URL" -ForegroundColor White
Write-Host "3. On your PC, open Chrome/Edge and go to:" -ForegroundColor White
Write-Host "   chrome://inspect/#devices" -ForegroundColor Cyan
Write-Host "4. Click 'inspect' on your iPhone's Safari tab" -ForegroundColor White
Write-Host "5. You'll see iPhone Safari in a new DevTools window!" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Starting ngrok..." -ForegroundColor Green
Write-Host "Keep this window open while debugging!" -ForegroundColor Yellow
Write-Host ""

try {
    ngrok http 8000
} catch {
    Write-Host "❌ ngrok not found. Please install ngrok first." -ForegroundColor Red
    Write-Host "Download from: https://ngrok.com/download" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
