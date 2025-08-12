#!/bin/bash

echo "🔧 Making shell scripts executable..."

chmod +x test-both-versions.sh
chmod +x copy-and-serve.sh
chmod +x quick-start.sh

echo "✅ All shell scripts are now executable!"
echo ""
echo "📋 Available commands:"
echo "   ./quick-start.sh      - Interactive menu for all options"
echo "   ./copy-and-serve.sh   - Copy files and start server"
echo "   ./test-both-versions.sh - Test both PWA versions"
echo ""
echo "🚀 Run ./quick-start.sh to get started!"
