#!/bin/bash

echo "🔗 Remote Debugging - iPhone Safari to Fedora/Arch"
echo "==================================================="
echo ""

echo "📱 iPhone Setup:"
echo "1. Connect iPhone to PC via USB cable"
echo "2. On iPhone: Trust this computer (if prompted)"
echo "3. Go to Settings → Safari → Advanced"
echo "4. Enable 'Web Inspector'"
echo "5. Make sure iPhone is unlocked"
echo ""

echo "💻 Fedora/Arch Setup:"
echo "1. Install ngrok via package manager"
echo "2. Install Chrome/Chromium for DevTools"
echo "3. No iTunes needed - Linux handles drivers"
echo ""

echo "📦 Installing ngrok:"
if command -v dnf &> /dev/null; then
    echo "Fedora detected - installing via dnf..."
    sudo dnf install ngrok
elif command -v pacman &> /dev/null; then
    echo "Arch detected - installing via pacman..."
    sudo pacman -S ngrok
else
    echo "❌ Package manager not supported. Installing manually..."
    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
    tar -xzf ngrok-v3-stable-linux-amd64.tgz
    sudo mv ngrok /usr/local/bin/
    rm ngrok-v3-stable-linux-amd64.tgz
fi

echo ""
echo "🌐 Starting ngrok tunnel..."
echo "This will give you a public URL for your iPhone"
echo ""

echo "📋 After ngrok starts:"
echo "1. Copy the ngrok URL (e.g., https://abc123.ngrok.io)"
echo "2. Open Safari on iPhone and go to that URL"
echo "3. On Linux, open Chrome/Chromium and go to:"
echo "   chrome://inspect/#devices"
echo "4. Your iPhone should appear under 'Remote Target'"
echo "5. Click 'inspect' on your iPhone's Safari tab"
echo "6. You'll see iPhone Safari in a new DevTools window!"
echo ""

echo "💡 Linux Benefits:"
echo "- Native performance"
echo "- Better USB device handling"
echo "- Package manager integration"
echo "- Full Linux toolchain access"
echo ""

echo "🚀 Starting ngrok..."
echo "Keep this terminal open while debugging!"
echo ""

ngrok http 8000
