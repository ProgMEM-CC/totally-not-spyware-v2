#!/bin/bash

echo "🔓 TotallyNotSpyware v2 - Copy Files & Start Server"
echo "=========================================="
echo ""
echo "Copying required files and starting server..."
echo ""

echo "📁 Navigating to project..."
cd /mnt/c/Users/RIZALINA/.cursor/Repos/totally-not-spyware-v2

echo "✅ Project directory found: $(pwd)"
echo ""

echo "📋 Copying required JavaScript files..."

# Copy required files to dist directory
if [ -d 'tns-pwa/dist' ]; then
    cp pwn.js tns-pwa/dist/ 2>/dev/null && echo "✅ Copied pwn.js" || echo "❌ Failed to copy pwn.js"
    cp stages.js tns-pwa/dist/ 2>/dev/null && echo "✅ Copied stages.js" || echo "❌ Failed to copy stages.js"
    cp offsets.js tns-pwa/dist/ 2>/dev/null && echo "✅ Copied offsets.js" || echo "❌ Failed to copy offsets.js"
    cp helper.js tns-pwa/dist/ 2>/dev/null && echo "✅ Copied helper.js" || echo "❌ Failed to copy helper.js"
    cp utils.js tns-pwa/dist/ 2>/dev/null && echo "✅ Copied utils.js" || echo "❌ Failed to copy utils.js"
    
    echo ""
    echo "📊 Files in dist directory:"
    ls -la tns-pwa/dist/*.js
    
    echo ""
    echo "🚀 Starting PWA server on port 8080..."
    echo "=========================================="
    echo ""
    echo "🌐 Your PWA is now accessible at:"
    echo "   PC: http://localhost:8080"
    echo "   iOS: http://172.25.129.238:8080"
    echo ""
    echo "📱 To test on iOS 12 device:"
    echo "   1. Open Safari on iOS device"
    echo "   2. Navigate to: http://172.25.129.238:8080"
    echo "   3. Tap Share button"
    echo "   4. Tap 'Add to Home Screen'"
    echo ""
    echo "🔧 To stop server: Ctrl + C"
    echo ""
    
    # Start the server
    cd tns-pwa/dist
    python3 -m http.server 8080
    
else
    echo "❌ tns-pwa/dist directory not found!"
    echo "Please run setup-pwa-scaffold.sh first."
    exit 1
fi
