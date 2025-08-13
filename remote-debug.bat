@echo off
echo 🔗 Remote Debugging - iPhone Safari to Windows
echo ===============================================
echo.
echo This will let you debug your iPhone Safari from your Windows PC!
echo.

echo 📱 On your iPhone:
echo 1. Go to Settings → Safari → Advanced
echo 2. Enable "Web Inspector"
echo 3. Make sure iPhone and PC are on same WiFi
echo.

echo 🌐 Starting ngrok tunnel...
echo This will give you a public URL for your iPhone
echo.

echo 💡 After ngrok starts:
echo 1. Copy the ngrok URL (e.g., https://abc123.ngrok.io)
echo 2. Open Safari on iPhone and go to that URL
echo 3. On your PC, open Chrome/Edge and go to:
echo    chrome://inspect/#devices
echo 4. Click "inspect" on your iPhone's Safari tab
echo.

echo 🚀 Starting ngrok...
ngrok http 8000

pause
