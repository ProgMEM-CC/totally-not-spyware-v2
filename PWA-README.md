# TotallyNotSpyware v2 - PWA for iOS 12 Chimera

A Progressive Web App (PWA) re-jailbreak utility for devices initially jailbroken with Chimera on iOS 12. This PWA can be installed to the home screen and works offline, providing a native app-like experience.

## 🌟 Features

- **Progressive Web App (PWA)** - Install to home screen, works offline
- **iOS 12 Chimera Compatible** - Specifically designed for Chimera jailbreak
- **WebKit Exploit** - Uses CVE-2020-9802 for code execution
- **No Code Signing Required** - Runs directly in Safari
- **Offline Support** - Service worker caches all necessary resources
- **Modern UI/UX** - Beautiful, responsive design optimized for mobile
- **Real-time Logging** - WebSocket-based logging system

## 📱 Supported Devices

- **iOS Versions**: 12.0 through 12.5.x
- **Device Types**: A7-A10 devices (iPhone 5s through iPhone X)
- **Jailbreak Requirement**: Must have been jailbroken at least once previously with Chimera

## 🚀 Quick Start

### Option 1: Windows + WSL2 (Recommended)

1. **Install WSL2** (if not already installed):
   ```powershell
   # Run as Administrator in PowerShell
   wsl --install
   ```

2. **Run the WSL2 launcher**:
   ```cmd
   start-wsl2.bat
   ```

3. **Set up development environment**:
   ```bash
   chmod +x setup-wsl2.sh
   ./setup-wsl2.sh
   ```

4. **Start development server**:
   ```bash
   dev-server
   ```

### Option 2: Direct WSL2

1. **Open WSL2 Ubuntu**:
   ```cmd
   wsl -d Ubuntu
   ```

2. **Navigate to project**:
   ```bash
   cd ~/totally-not-spyware-v2
   ```

3. **Set up environment**:
   ```bash
   chmod +x setup-wsl2.sh
   ./setup-wsl2.sh
   ```

4. **Start server**:
   ```bash
   python3 server.py
   ```

## 🔧 Development Environment

The setup script installs all necessary tools for iOS development:

### Core Tools
- **Theos** - iOS development framework
- **Xtools** - iOS toolchain and SDKs
- **ldid** - Code signing utility
- **jtool2** - Mach-O manipulation tool
- **ios-deploy** - Device deployment tool

### Development Tools
- **Python 3.7+** - Backend server and build scripts
- **Node.js 18+** - PWA development tools
- **Build tools** - CMake, Ninja, pkg-config
- **Development libraries** - SSL, FFI, multimedia support

### PWA Development
- **Service Worker** - Offline functionality and caching
- **Web App Manifest** - App installation and appearance
- **iOS-specific meta tags** - Home screen integration
- **Responsive design** - Mobile-first UI/UX

## 📁 Project Structure

```
totally-not-spyware-v2/
├── index.html              # Main PWA interface
├── manifest.json           # PWA manifest
├── sw.js                  # Service worker
├── server.py              # Python backend server
├── setup-wsl2.sh          # WSL2 setup script
├── start-wsl2.bat         # Windows WSL2 launcher
├── requirements.txt        # Python dependencies
├── package.json            # Node.js dependencies
├── stages/                 # iOS jailbreak stages
│   ├── build.py           # Build script
│   ├── physpuppet/        # Kernel exploit
│   └── stage3/            # Jailbreak implementation
├── icons/                  # PWA icons (create these)
└── PWA-README.md          # This file
```

## 🎨 PWA Icons

You need to create the following icon sizes for full PWA support:

- `72x72` - Small Android
- `96x96` - Medium Android
- `128x128` - Large Android
- `144x144` - Windows tiles
- `152x152` - iOS home screen
- `192x192` - Android home screen
- `384x384` - Android splash
- `512x512` - Android splash

### Icon Creation Script

```bash
# Install ImageMagick if not already installed
sudo apt install imagemagick

# Create icons directory
mkdir -p icons

# Create icons from a 512x512 source image
convert source-icon.png -resize 72x72 icons/icon-72x72.png
convert source-icon.png -resize 96x96 icons/icon-96x96.png
convert source-icon.png -resize 128x128 icons/icon-128x128.png
convert source-icon.png -resize 144x144 icons/icon-144x144.png
convert source-icon.png -resize 152x152 icons/icon-152x152.png
convert source-icon.png -resize 192x192 icons/icon-192x192.png
convert source-icon.png -resize 384x384 icons/icon-384x384.png
convert source-icon.png -resize 512x512 icons/icon-512x512.png
```

## 🚀 Building and Deployment

### Development Build
```bash
# Start development server
python3 server.py

# Or use the shortcut
dev-server
```

### Production Build
```bash
# Build iOS target
python3 stages/build.py

# Or use the shortcut
build-ios
```

### Release Build
```bash
# Create release package
python3 release.py

# Or use the shortcut
deploy-ios
```

## 📱 Testing on iOS Device

1. **Connect iOS device** via USB
2. **Trust the computer** on your device
3. **Open Safari** on your device
4. **Navigate to your server** (e.g., `http://your-ip:8000`)
5. **Add to Home Screen** using Safari's share button
6. **Launch the PWA** from home screen

### Network Configuration

For testing on physical device, you need to expose your WSL2 server:

```bash
# Find your WSL2 IP
ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1

# Expose server to network (replace YOUR_IP with actual IP)
python3 server.py --host 0.0.0.0 --port 8000
```

## 🔒 Security Considerations

- **HTTPS Required** - PWA features require secure context in production
- **Local Development** - HTTP is fine for local development and testing
- **Code Signing** - No code signing required for WebKit exploits
- **Sandboxing** - Runs in Safari's sandboxed environment

## 🐛 Troubleshooting

### Common Issues

1. **PWA not installing**:
   - Ensure HTTPS in production
   - Check manifest.json syntax
   - Verify service worker registration

2. **Service worker not working**:
   - Check browser console for errors
   - Verify sw.js file is accessible
   - Clear browser cache

3. **Build failures**:
   - Ensure all dependencies are installed
   - Check Python virtual environment is activated
   - Verify Theos and Xtools are properly configured

4. **Device connection issues**:
   - Install libimobiledevice tools
   - Check USB connection and trust settings
   - Verify device is unlocked

### Debug Commands

```bash
# Check WSL2 status
wsl --status

# Check Ubuntu distribution
wsl -l -v

# Check Python environment
python3 --version
pip3 list

# Check Node.js environment
node --version
npm --version

# Check iOS tools
which theos
which ldid
which jtool2
```

## 📚 Additional Resources

- [PWA Documentation](https://web.dev/progressive-web-apps/)
- [iOS Web App Guidelines](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html)
- [Theos Documentation](https://github.com/theos/theos/wiki)
- [Chimera Jailbreak](https://chimera.sh/)
- [WebKit Exploits](https://webkit.org/security/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on iOS 12 device
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

- **wh1te4ever** - Main developer
- **alfiecg24** - Stable kernel exploit
- **felix-pb** - Kernel exploit
- **Samuel Groß** - CVE-2020-9802 WebKit exploit
- **CoolStar** - Chimera jailbreak
- **JakeBlair420** - JOP chaining and code execution idea
- **qwertyoruiop** - Mach-O loader with +jitMemCpy

---

**⚠️ Disclaimer**: This tool is for educational and research purposes only. Use at your own risk and only on devices you own. The developers are not responsible for any damage to devices or data loss.
