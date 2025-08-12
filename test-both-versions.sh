#!/bin/bash

echo "🔓 TotallyNotSpyware v2 - Test Both Versions"
echo "=========================================="
echo ""
echo "Testing both modern PWA and legacy versions..."
echo ""

echo "📁 Navigating to project..."
cd /mnt/c/Users/RIZALINA/.cursor/Repos/totally-not-spyware-v2/tns-pwa/dist

echo "✅ Project directory found: $(pwd)"
echo ""

echo "📋 Checking files..."
ls -la *.html *.js

echo ""
echo "🚀 Starting server on port 8080..."
echo "=========================================="
echo ""
echo "🌐 Your PWA is now accessible at:"
echo "   PC: http://localhost:8080"
echo "   iOS: http://172.25.129.238:8080"
echo "   ngrok: https://d28ca5b0c1c3.ngrok-free.app"
echo ""
echo "📱 iOS Version Detection:"
echo "   iOS 13+: Modern PWA (index.html)"
echo "   iOS 12-: Legacy version (legacy.html)"
echo ""
echo "🔧 To test:"
echo "   1. Open on iOS 12 device - should redirect to legacy.html"
echo "   2. Open on iOS 13+ device - should load modern PWA"
echo "   3. Open on Android/PC - should load modern PWA"
echo ""

# Start the server
python3 -m http.server 8080
