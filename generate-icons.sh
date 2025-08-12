#!/bin/bash

# TotallyNotSpyware v2 - PWA Icon Generator
# This script generates all necessary PWA icons from a source image

set -e

echo "🎨 Generating PWA icons for TotallyNotSpyware v2..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Installing..."
    sudo apt update
    sudo apt install -y imagemagick
fi

# Check if source image exists
SOURCE_IMAGE="source-icon.png"
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Source image '$SOURCE_IMAGE' not found!"
    echo ""
    echo "Please create a 512x512 PNG image named '$SOURCE_IMAGE' in the current directory."
    echo "You can use any image editor to create a simple icon with:"
    echo "  - Size: 512x512 pixels"
    echo "  - Format: PNG with transparency support"
    echo "  - Design: Simple, recognizable icon (e.g., lock/unlock symbol)"
    echo ""
    echo "Example using GIMP or Photoshop:"
    echo "  1. Create new 512x512 image"
    echo "  2. Design your icon"
    echo "  3. Export as PNG"
    echo "  4. Save as 'source-icon.png'"
    echo ""
    exit 1
fi

# Create icons directory
mkdir -p icons

echo "📁 Creating icons directory..."

# Generate all required icon sizes
echo "🔄 Generating icons..."

# Standard PWA icons
convert "$SOURCE_IMAGE" -resize 72x72 icons/icon-72x72.png
convert "$SOURCE_IMAGE" -resize 96x96 icons/icon-96x96.png
convert "$SOURCE_IMAGE" -resize 128x128 icons/icon-128x128.png
convert "$SOURCE_IMAGE" -resize 144x144 icons/icon-144x144.png
convert "$SOURCE_IMAGE" -resize 152x152 icons/icon-152x152.png
convert "$SOURCE_IMAGE" -resize 192x192 icons/icon-192x192.png
convert "$SOURCE_IMAGE" -resize 384x384 icons/icon-384x384.png
convert "$SOURCE_IMAGE" -resize 512x512 icons/icon-512x512.png

# iOS specific icons
convert "$SOURCE_IMAGE" -resize 180x180 icons/icon-180x180.png

# Create splash screen images for iOS
echo "📱 Generating iOS splash screen images..."

# iPad Pro 12.9" (2048x2732)
convert "$SOURCE_IMAGE" -resize 2048x2732 -background '#000000' -gravity center -extent 2048x2732 icons/splash-2048x2732.png

# iPad Pro 11" (1668x2388)
convert "$SOURCE_IMAGE" -resize 1668x2388 -background '#000000' -gravity center -extent 1668x2388 icons/splash-1668x2388.png

# iPad (1536x2048)
convert "$SOURCE_IMAGE" -resize 1536x2048 -background '#000000' -gravity center -extent 1536x2048 icons/splash-1536x2048.png

# iPhone X/XS/11 Pro (1125x2436)
convert "$SOURCE_IMAGE" -resize 1125x2436 -background '#000000' -gravity center -extent 1125x2436 icons/splash-1125x2436.png

# iPhone XR/11 (1242x2688)
convert "$SOURCE_IMAGE" -resize 1242x2688 -background '#000000' -gravity center -extent 1242x2688 icons/splash-1242x2688.png

# iPhone 6/7/8 (750x1334)
convert "$SOURCE_IMAGE" -resize 750x1334 -background '#000000' -gravity center -extent 750x1334 icons/splash-750x1334.png

# iPhone 5/SE (640x1136)
convert "$SOURCE_IMAGE" -resize 640x1136 -background '#000000' -gravity center -extent 640x1136 icons/splash-640x1136.png

# Create a simple default icon if source doesn't exist
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "⚠️  Creating default icon..."
    
    # Create a simple lock/unlock icon using ImageMagick
    convert -size 512x512 xc:transparent \
        -fill '#ff6b6b' \
        -stroke '#ffffff' \
        -strokewidth 8 \
        -draw "circle 256,256 256,100" \
        -fill 'none' \
        -draw "path 'M 200,200 L 200,300 L 312,300 L 312,200 Z'" \
        -fill '#ff6b6b' \
        -draw "circle 256,250 256,220" \
        icons/icon-512x512.png
    
    # Generate all sizes from the default icon
    convert icons/icon-512x512.png -resize 72x72 icons/icon-72x72.png
    convert icons/icon-512x512.png -resize 96x96 icons/icon-96x96.png
    convert icons/icon-512x512.png -resize 128x128 icons/icon-128x128.png
    convert icons/icon-512x512.png -resize 144x144 icons/icon-144x144.png
    convert icons/icon-512x512.png -resize 152x152 icons/icon-152x152.png
    convert icons/icon-512x512.png -resize 192x192 icons/icon-192x192.png
    convert icons/icon-512x512.png -resize 384x384 icons/icon-384x384.png
    convert icons/icon-512x512.png -resize 180x180 icons/icon-180x180.png
fi

# Verify all icons were created
echo "✅ Verifying icons..."
ICON_COUNT=$(ls icons/*.png 2>/dev/null | wc -l)
echo "📊 Generated $ICON_COUNT icon files"

# List all created icons
echo "📁 Icons created:"
ls -la icons/

echo ""
echo "🎉 PWA icons generated successfully!"
echo ""
echo "📱 Your PWA now has all necessary icons for:"
echo "   - Android devices (72x72 to 512x512)"
echo "   - iOS devices (152x152, 180x180)"
echo "   - iOS splash screens (all device sizes)"
echo ""
echo "🚀 Next steps:"
echo "   1. Test your PWA in a browser"
echo "   2. Install to home screen on mobile device"
echo "   3. Verify all icons display correctly"
echo ""
echo "💡 Tip: You can customize the source icon and run this script again"
echo "   to regenerate all icons with your new design."
