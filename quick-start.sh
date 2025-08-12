#!/bin/bash

echo "🚀 TotallyNotSpyware v2 - Quick Start"
echo "====================================="
echo ""

# Check if we're in the right directory
if [ ! -f "setup-pwa-scaffold.sh" ]; then
    echo "❌ Please run this script from the project root directory"
    echo "   cd /mnt/c/Users/RIZALINA/.cursor/Repos/totally-not-spyware-v2"
    exit 1
fi

echo "📋 Quick start options:"
echo "1. Setup PWA scaffold and build"
echo "2. Copy files and start server"
echo "3. Just start server (if already built)"
echo "4. Test both versions"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "🔧 Setting up PWA scaffold..."
        chmod +x setup-pwa-scaffold.sh
        ./setup-pwa-scaffold.sh
        
        echo "🚀 Building PWA..."
        cd tns-pwa
        chmod +x build-pwa.sh
        ./build-pwa.sh
        
        echo "📋 Copying required files..."
        cd ..
        chmod +x copy-and-serve.sh
        ./copy-and-serve.sh
        ;;
    2)
        echo "📋 Copying files and starting server..."
        chmod +x copy-and-serve.sh
        ./copy-and-serve.sh
        ;;
    3)
        echo "🚀 Starting server..."
        cd tns-pwa/dist
        python3 -m http.server 8080
        ;;
    4)
        echo "🧪 Testing both versions..."
        chmod +x test-both-versions.sh
        ./test-both-versions.sh
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac
