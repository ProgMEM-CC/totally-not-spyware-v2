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
