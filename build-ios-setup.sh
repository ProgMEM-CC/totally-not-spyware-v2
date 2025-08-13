#!/bin/bash

# iOS IPA Build Setup for TotallyNotSpyware v2
# This script prepares the iOS wrapper for building on macOS

set -e

echo "📱 Setting up iOS IPA build environment..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  This script is designed for macOS, but you can prepare the environment now."
    echo "   The actual build will need to happen on macOS with Xcode installed."
fi

# Check if we have the PWA built
if [ ! -d "tns-pwa/dist" ]; then
    echo "❌ PWA not built yet. Building first..."
    if [ -f "tns-pwa/build-pwa.sh" ]; then
        cd tns-pwa
        ./build-pwa.sh
        cd ..
    else
        echo "❌ PWA build script not found. Please build the PWA first."
        exit 1
    fi
fi

# Create iOS wrapper directory structure
echo "📁 Creating iOS wrapper structure..."
mkdir -p ios-wrapper/TotallyNotSpyware/PWA
mkdir -p ios-wrapper/TotallyNotSpyware/Assets.xcassets/AppIcon.appiconset
mkdir -p ios-wrapper/TotallyNotSpyware/Base.lproj

# Copy PWA files to the iOS wrapper
echo "📦 Copying PWA files..."
cp -r tns-pwa/dist/* ios-wrapper/TotallyNotSpyware/PWA/

# Create AppIcon.appiconset/Contents.json
cat > ios-wrapper/TotallyNotSpyware/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create LaunchScreen.storyboard
cat > ios-wrapper/TotallyNotSpyware/Base.lproj/LaunchScreen.storyboard << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="21507" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="21505"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="System colors in document resources" minToolsVersion="11.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <!--View Controller-->
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="LaunchImage" translatesAutoresizingMaskIntoConstraints="NO" id="YRO-k0-Ey4">
                                <rect key="frame" x="96.666666666666686" y="326" width="200" height="200"/>
                                <constraints>
                                    <constraint firstAttribute="width" constant="200" id="1Gr-wE-5Xf"/>
                                    <constraint firstAttribute="height" constant="200" id="Q3B-4B-g5h"/>
                                </constraints>
                            </imageView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                        <constraints>
                            <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="3p8-FC-h6j"/>
                            <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="Q3B-4B-g5h"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="LaunchImage" width="200" height="200"/>
        <systemColor name="systemBackgroundColor">
            <color white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
        </systemColor>
    </resources>
</document>
EOF

# Create Assets.xcassets/Contents.json
cat > ios-wrapper/TotallyNotSpyware/Assets.xcassets/Contents.json << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create a simple build script for macOS
cat > ios-wrapper/build-ipa.sh << 'EOF'
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
EOF

# Make the build script executable
chmod +x ios-wrapper/build-ipa.sh

# Create a README for the build process
cat > ios-wrapper/README.md << 'EOF'
# iOS IPA Build Instructions

## Prerequisites
- macOS with Xcode installed
- Apple Developer Account (for signing)
- Valid provisioning profile

## Build Steps

1. **Prepare the environment** (run this on any system):
   ```bash
   ./build-ios-setup.sh
   ```

2. **Build the IPA** (run this on macOS):
   ```bash
   cd ios-wrapper
   ./build-ipa.sh
   ```

## Configuration

Before building, you need to:

1. **Update the bundle identifier** in `TotallyNotSpyware/Info.plist`
2. **Add your Team ID** in `build-ipa.sh`
3. **Add your provisioning profile** in `build-ipa.sh`

## Troubleshooting

- **Code signing errors**: Ensure you have a valid provisioning profile
- **Build failures**: Check that all PWA files are present in the `PWA/` directory
- **Icon issues**: Verify that `Assets.xcassets/AppIcon.appiconset/` contains proper icon files

## Output

The build will create:
- `build/TotallyNotSpyware.xcarchive` - Xcode archive
- `build/TotallyNotSpyware.ipa` - iOS app package
- `build/exportOptions.plist` - Export configuration
EOF

echo "✅ iOS build environment setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Switch to macOS with Xcode installed"
echo "2. Run: cd ios-wrapper && ./build-ipa.sh"
echo "3. Update the bundle identifier and signing information"
echo ""
echo "📁 Files created:"
echo "   - ios-wrapper/TotallyNotSpyware/PWA/ (PWA files)"
echo "   - ios-wrapper/TotallyNotSpyware/Assets.xcassets/ (App icons)"
echo "   - ios-wrapper/TotallyNotSpyware/Base.lproj/ (Launch screen)"
echo "   - ios-wrapper/build-ipa.sh (Build script)"
echo "   - ios-wrapper/README.md (Build instructions)"
