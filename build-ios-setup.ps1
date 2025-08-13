# iOS IPA Build Setup for TotallyNotSpyware v2
# This script prepares the iOS wrapper for building on macOS

param(
    [switch]$Force
)

Write-Host "📱 Setting up iOS IPA build environment..." -ForegroundColor Green

# Check if we have the PWA built
if (-not (Test-Path "tns-pwa/dist")) {
    Write-Host "❌ PWA not built yet. Building first..." -ForegroundColor Yellow
    if (Test-Path "tns-pwa/build-pwa.sh") {
        Write-Host "Running PWA build script..." -ForegroundColor Yellow
        bash tns-pwa/build-pwa.sh
    } else {
        Write-Host "❌ PWA build script not found. Please build the PWA first." -ForegroundColor Red
        exit 1
    }
}

# Create iOS wrapper directory structure
Write-Host "📁 Creating iOS wrapper structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "ios-wrapper/TotallyNotSpyware/PWA" | Out-Null
New-Item -ItemType Directory -Force -Path "ios-wrapper/TotallyNotSpyware/Assets.xcassets/AppIcon.appiconset" | Out-Null
New-Item -ItemType Directory -Force -Path "ios-wrapper/TotallyNotSpyware/Base.lproj" | Out-Null

# Copy PWA files to the iOS wrapper
Write-Host "📦 Copying PWA files..." -ForegroundColor Yellow
Copy-Item -Path "tns-pwa/dist/*" -Destination "ios-wrapper/TotallyNotSpyware/PWA/" -Recurse -Force

# Create AppIcon.appiconset/Contents.json
$appIconJson = @"
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
"@

$appIconJson | Out-File -FilePath "ios-wrapper/TotallyNotSpyware/Assets.xcassets/AppIcon.appiconset/Contents.json" -Encoding UTF8

# Create LaunchScreen.storyboard
$launchScreenStoryboard = @"
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
"@

$launchScreenStoryboard | Out-File -FilePath "ios-wrapper/TotallyNotSpyware/Base.lproj/LaunchScreen.storyboard" -Encoding UTF8

# Create Assets.xcassets/Contents.json
$assetsJson = @"
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"@

$assetsJson | Out-File -FilePath "ios-wrapper/TotallyNotSpyware/Assets.xcassets/Contents.json" -Encoding UTF8

# Create a simple build script for macOS
$buildScript = @"
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
"@

$buildScript | Out-File -FilePath "ios-wrapper/build-ipa.sh" -Encoding UTF8

# Create a README for the build process
$readme = @"
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
   or on Windows:
   ```powershell
   .\build-ios-setup.ps1
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

## Windows Users

If you're on Windows, you can prepare the environment using the PowerShell script, but the actual build must happen on macOS with Xcode installed.
"@

$readme | Out-File -FilePath "ios-wrapper/README.md" -Encoding UTF8

Write-Host "✅ iOS build environment setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Switch to macOS with Xcode installed" -ForegroundColor White
Write-Host "2. Run: cd ios-wrapper && ./build-ipa.sh" -ForegroundColor White
Write-Host "3. Update the bundle identifier and signing information" -ForegroundColor White
Write-Host ""
Write-Host "📁 Files created:" -ForegroundColor Yellow
Write-Host "   - ios-wrapper/TotallyNotSpyware/PWA/ (PWA files)" -ForegroundColor White
Write-Host "   - ios-wrapper/TotallyNotSpyware/Assets.xcassets/ (App icons)" -ForegroundColor White
Write-Host "   - ios-wrapper/TotallyNotSpyware/Base.lproj/ (Launch screen)" -ForegroundColor White
Write-Host "   - ios-wrapper/build-ipa.sh (Build script)" -ForegroundColor White
Write-Host "   - ios-wrapper/README.md (Build instructions)" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: The actual IPA build requires macOS with Xcode installed." -ForegroundColor Yellow
Write-Host "   This script only prepares the environment for building." -ForegroundColor Yellow
