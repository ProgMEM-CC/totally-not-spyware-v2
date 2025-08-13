# Remote Debugging - iPhone Safari to Windows (USB)
Write-Host "🔗 Remote Debugging - iPhone Safari to Windows (USB)" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📱 iPhone Setup:" -ForegroundColor Yellow
Write-Host "1. Connect iPhone to PC via USB cable" -ForegroundColor Green
Write-Host "2. On iPhone: Trust this computer (if prompted)" -ForegroundColor White
Write-Host "3. Go to Settings → Safari → Advanced" -ForegroundColor White
Write-Host "4. Enable 'Web Inspector'" -ForegroundColor White
Write-Host "5. Make sure iPhone is unlocked" -ForegroundColor White
Write-Host ""

Write-Host "💻 Windows Setup:" -ForegroundColor Yellow
Write-Host "1. Install Chrome or Edge (if not already)" -ForegroundColor White
Write-Host "2. Make sure ngrok is installed" -ForegroundColor White
Write-Host "3. Install iTunes (for iPhone drivers)" -ForegroundColor White
Write-Host ""

Write-Host "🌐 Starting ngrok tunnel..." -ForegroundColor Green
Write-Host "This will give you a public URL for your iPhone" -ForegroundColor White
Write-Host ""

Write-Host "📋 After ngrok starts:" -ForegroundColor Magenta
Write-Host "1. Copy the ngrok URL (e.g., https://abc123.ngrok.io)" -ForegroundColor White
Write-Host "2. Open Safari on iPhone and go to that URL" -ForegroundColor White
Write-Host "3. On your PC, open Chrome/Edge and go to:" -ForegroundColor White
Write-Host "   chrome://inspect/#devices" -ForegroundColor Cyan
Write-Host "4. Your iPhone should appear under 'Remote Target'" -ForegroundColor Green
Write-Host "5. Click 'inspect' on your iPhone's Safari tab" -ForegroundColor White
Write-Host "6. You'll see iPhone Safari in a new DevTools window!" -ForegroundColor Green
Write-Host ""

Write-Host "💡 USB Benefits:" -ForegroundColor Yellow
Write-Host "- Faster debugging connection" -ForegroundColor White
Write-Host "- More reliable than WiFi" -ForegroundColor White
Write-Host "- Full DevTools access" -ForegroundColor White
Write-Host "- Works without WiFi" -ForegroundColor White
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
