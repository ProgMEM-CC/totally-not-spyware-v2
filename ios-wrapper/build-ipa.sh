#!/bin/bash

# Build iOS IPA for TotallyNotSpyware v2
# This script must be run on macOS with Xcode installed

set -e

echo "📱 Building iOS IPA..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS with Xcode installed"
    exit 1
fi

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ xcodebuild not found. Please install Xcode from the App Store"
    exit 1
fi

# Navigate to the project directory
cd TotallyNotSpyware

# Create build directory
mkdir -p build

echo "🏗️  Building archive..."

# Build archive
xcodebuild \
    -project TotallyNotSpyware.xcodeproj \
    -scheme TotallyNotSpyware \
    -configuration Release \
    -archivePath "$PWD/build/TotallyNotSpyware.xcarchive" \
    build archive

if [ $? -eq 0 ]; then
    echo "✅ Archive built successfully!"
else
    echo "❌ Archive build failed!"
    exit 1
fi

echo "📦 Exporting IPA..."

# Create export options plist
cat > build/exportOptions.plist << 'EXPORTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.totallynotspyware.app</key>
        <string>YOUR_PROVISIONING_PROFILE</string>
    </dict>
    <key>signingCertificate</key>
    <string>iPhone Developer</string>
</dict>
</plist>
EXPORTEOF

# Export IPA
xcodebuild -exportArchive \
    -archivePath "$PWD/build/TotallyNotSpyware.xcarchive" \
    -exportOptionsPlist "$PWD/build/exportOptions.plist" \
    -exportPath "$PWD/build"

if [ $? -eq 0 ]; then
    echo "✅ IPA exported successfully!"
    
    # Find the IPA file
    IPA_FILE=$(find build -name "*.ipa" | head -1)
    if [ -n "$IPA_FILE" ]; then
        echo "📱 IPA file: $IPA_FILE"
        echo "📏 File size: $(du -h "$IPA_FILE" | cut -f1)"
    fi
else
    echo "❌ IPA export failed!"
    exit 1
fi

echo "🎉 iOS IPA build completed successfully!"
echo "📁 Build files are in: $PWD/build"

cd ..
