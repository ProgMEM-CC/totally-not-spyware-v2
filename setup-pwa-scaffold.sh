#!/bin/bash

# TotallyNotSpyware v2 - PWA Scaffold Setup
# This script sets up the PWA scaffold using PWABuilder's whisper starter

set -e

echo "🎨 Setting up PWA scaffold for TotallyNotSpyware v2..."

# Check if we're in the right directory
if [ ! -f "index.html" ] || [ ! -f "manifest.json" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Installing..."
    sudo apt install -y npm
fi

echo "📦 Installing PWA scaffold dependencies..."

# Create PWA scaffold directory
PWA_DIR="tns-pwa"
if [ -d "$PWA_DIR" ]; then
    echo "⚠️  PWA scaffold directory already exists. Removing..."
    rm -rf "$PWA_DIR"
fi

# Clone PWABuilder whisper starter
echo "🔗 Cloning PWABuilder whisper starter..."
git clone https://github.com/pwa-builder/pwa-whisper-starter.git "$PWA_DIR"
cd "$PWA_DIR"

# Install dependencies
echo "📥 Installing npm dependencies..."
npm install

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p public/stages public/icons public/assets

# Copy project files to PWA scaffold
echo "📋 Injecting TotallyNotSpyware v2 payload into PWA..."

# Copy main HTML and JS files
cp ../index_release.html ./public/index.html
cp ../pwn.js ./public/
cp ../utils.js ./public/
cp ../helper.js ./public/
cp ../int64.js ./public/
cp ../stages.js ./public/
cp ../offsets.js ./public/

# Copy stages directory contents
if [ -d "../stages" ]; then
    echo "📦 Copying stages components..."
    find ../stages -name "*.js" -exec cp {} ./public/stages/ \;
    find ../stages -name "*.dylib" -exec cp {} ./public/stages/ \;
    find ../stages -name "*.so" -exec cp {} ./public/stages/ \;
fi

# Copy icons if they exist
if [ -d "../icons" ]; then
    echo "🎨 Copying PWA icons..."
    cp ../icons/*.png ./public/icons/ 2>/dev/null || true
fi

# Copy manifest
cp ../manifest.json ./public/manifest.webmanifest

# Update the PWA scaffold configuration
echo "⚙️  Configuring PWA scaffold..."

# Update package.json
cat > package.json << 'EOF'
{
  "name": "totally-not-spyware-v2-pwa",
  "version": "2.0.0",
  "description": "TotallyNotSpyware v2 - PWA for iOS 12 Chimera",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:run": "vitest run",
    "lint": "eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix --ignore-path .gitignore",
    "format": "prettier --write src/",
    "typecheck": "vue-tsc --noEmit"
  },
  "dependencies": {
    "vue": "^3.3.4",
    "vue-router": "^4.2.4",
    "pinia": "^2.1.6",
    "@vitejs/plugin-vue": "^4.2.3",
    "vite": "^4.4.5",
    "vite-plugin-pwa": "^0.16.4",
    "workbox-window": "^7.0.0"
  },
  "devDependencies": {
    "@rushstack/eslint-patch": "^1.3.2",
    "@tsconfig/node18": "^18.2.2",
    "@types/node": "^18.17.17",
    "@vitejs/plugin-vue": "^4.2.3",
    "@vue/eslint-config-prettier": "^8.0.0",
    "@vue/eslint-config-typescript": "^11.0.3",
    "@vue/tsconfig": "^0.4.0",
    "eslint": "^8.45.0",
    "eslint-plugin-vue": "^9.15.1",
    "npm-run-all2": "^6.1.1",
    "prettier": "^3.0.0",
    "typescript": "~5.1.6",
    "vite": "^4.4.5",
    "vite-plugin-pwa": "^0.16.4",
    "vue-tsc": "^1.8.5",
    "vitest": "^0.34.3",
    "@vitest/ui": "^0.34.3"
  },
  "keywords": [
    "jailbreak",
    "ios12",
    "chimera",
    "pwa",
    "webkit-exploit",
    "vue3"
  ],
  "author": "wh1te4ever",
  "license": "MIT"
}
EOF

# Update Vite configuration for PWA
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    vue(),
    VitePWA({
      registerType: 'autoUpdate',
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,dylib,so}'],
        runtimeCaching: [
          {
            urlPattern: /^https:\/\/.*\.(?:png|jpg|jpeg|svg|gif)$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'images-cache',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 60 * 60 * 24 * 30 // 30 days
              }
            }
          }
        ]
      },
      manifest: {
        name: 'TotallyNotSpyware v2',
        short_name: 'TNSv2',
        description: 'Re-jailbreak utility for devices initially jailbroken with Chimera on iOS 12',
        theme_color: '#000000',
        background_color: '#000000',
        display: 'standalone',
        orientation: 'portrait-primary',
        scope: '/',
        start_url: '/',
        icons: [
          {
            src: 'icons/icon-72x72.png',
            sizes: '72x72',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-96x96.png',
            sizes: '96x96',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-128x128.png',
            sizes: '128x128',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-144x144.png',
            sizes: '144x144',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-152x152.png',
            sizes: '152x152',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-384x384.png',
            sizes: '384x384',
            type: 'image/png',
            purpose: 'any maskable'
          },
          {
            src: 'icons/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable'
          }
        ]
      }
    })
  ],
  server: {
    host: '0.0.0.0',
    port: 3000
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      input: {
        main: 'index.html'
      }
    }
  }
})
EOF

# Create a simple Vue component for the jailbreak interface
mkdir -p src/components
cat > src/components/JailbreakInterface.vue << 'EOF'
<template>
  <div class="jailbreak-interface">
    <div class="header">
      <h1>🔓 TotallyNotSpyware v2</h1>
      <p>iOS 12 Chimera Re-Jailbreak Utility</p>
    </div>
    
    <div class="status-panel">
      <div class="status-item" :class="{ active: isConnected }">
        <span class="status-icon">{{ isConnected ? '✅' : '❌' }}</span>
        <span class="status-text">WebSocket: {{ isConnected ? 'Connected' : 'Disconnected' }}</span>
      </div>
      
      <div class="status-item" :class="{ active: isReady }">
        <span class="status-icon">{{ isReady ? '✅' : '⏳' }}</span>
        <span class="status-text">Ready: {{ isReady ? 'Yes' : 'No' }}</span>
      </div>
    </div>
    
    <div class="action-panel">
      <button 
        @click="startJailbreak" 
        :disabled="!isReady || isRunning"
        class="jailbreak-button"
        :class="{ running: isRunning }"
      >
        {{ isRunning ? '🚀 Jailbreaking...' : '🚀 Start Jailbreak' }}
      </button>
      
      <button 
        @click="checkStatus" 
        class="status-button"
      >
        🔍 Check Status
      </button>
    </div>
    
    <div class="log-panel">
      <h3>📋 Activity Log</h3>
      <div class="log-content" ref="logContent">
        <div 
          v-for="(log, index) in logs" 
          :key="index" 
          class="log-entry"
          :class="log.type"
        >
          <span class="log-time">{{ log.time }}</span>
          <span class="log-message">{{ log.message }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'

// Reactive state
const isConnected = ref(false)
const isReady = ref(false)
const isRunning = ref(false)
const logs = ref([])
const logContent = ref(null)

// Add log entry
const addLog = (message, type = 'info') => {
  const timestamp = new Date().toLocaleTimeString()
  logs.value.push({ time: timestamp, message, type })
  
  // Auto-scroll to bottom
  nextTick(() => {
    if (logContent.value) {
      logContent.value.scrollTop = logContent.value.scrollHeight
    }
  })
}

// WebSocket connection
let ws = null

const connectWebSocket = () => {
  try {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${protocol}//${window.location.host}/WebSocket`
    
    ws = new WebSocket(wsUrl)
    
    ws.onopen = () => {
      isConnected.value = true
      addLog('WebSocket connected', 'success')
      ws.send('totally-not-spyware-v2')
    }
    
    ws.onmessage = (event) => {
      addLog(`Received: ${event.data}`, 'info')
    }
    
    ws.onerror = (error) => {
      addLog(`WebSocket error: ${error}`, 'error')
      isConnected.value = false
    }
    
    ws.onclose = () => {
      addLog('WebSocket disconnected', 'warning')
      isConnected.value = false
    }
  } catch (error) {
    addLog(`WebSocket connection failed: ${error.message}`, 'error')
  }
}

// Start jailbreak process
const startJailbreak = async () => {
  if (!isReady.value || isRunning.value) return
  
  isRunning.value = true
  addLog('Starting jailbreak process...', 'info')
  
  try {
    // Call the pwn function from pwn.js
    if (typeof window.pwn === 'function') {
      window.pwn()
      addLog('Jailbreak function called', 'success')
    } else {
      addLog('Jailbreak function not found', 'error')
    }
  } catch (error) {
    addLog(`Jailbreak error: ${error.message}`, 'error')
  } finally {
    isRunning.value = false
  }
}

// Check system status
const checkStatus = () => {
  addLog('Checking system status...', 'info')
  
  // Check if all required files are loaded
  const requiredFiles = ['pwn.js', 'stages.js', 'offsets.js']
  const missingFiles = requiredFiles.filter(file => !window[file.replace('.js', '')])
  
  if (missingFiles.length === 0) {
    addLog('All required files loaded', 'success')
    isReady.value = true
  } else {
    addLog(`Missing files: ${missingFiles.join(', ')}`, 'error')
    isReady.value = false
  }
}

// Initialize on mount
onMounted(() => {
  addLog('Jailbreak interface initialized', 'info')
  connectWebSocket()
  checkStatus()
  
  // Check status every 5 seconds
  setInterval(checkStatus, 5000)
})
</script>

<style scoped>
.jailbreak-interface {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.header h1 {
  color: #ff6b6b;
  margin: 0;
  font-size: 2.5em;
}

.header p {
  color: #666;
  margin: 10px 0 0 0;
}

.status-panel {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 15px;
  margin-bottom: 30px;
}

.status-item {
  background: rgba(255, 255, 255, 0.1);
  padding: 15px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-item.active {
  border-color: #51cf66;
  background: rgba(81, 207, 102, 0.1);
}

.status-icon {
  font-size: 1.2em;
}

.action-panel {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
  justify-content: center;
}

.jailbreak-button, .status-button {
  padding: 15px 30px;
  border: none;
  border-radius: 25px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.jailbreak-button {
  background: linear-gradient(45deg, #ff6b6b, #ee5a24);
  color: white;
}

.jailbreak-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(255, 107, 107, 0.4);
}

.jailbreak-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.jailbreak-button.running {
  background: linear-gradient(45deg, #51cf66, #40c057);
}

.status-button {
  background: #6c757d;
  color: white;
}

.status-button:hover {
  background: #5a6268;
}

.log-panel {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 8px;
  padding: 20px;
}

.log-panel h3 {
  margin: 0 0 15px 0;
  color: #333;
}

.log-content {
  max-height: 300px;
  overflow-y: auto;
  background: rgba(0, 0, 0, 0.02);
  border-radius: 4px;
  padding: 10px;
}

.log-entry {
  padding: 5px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  display: flex;
  gap: 10px;
}

.log-entry:last-child {
  border-bottom: none;
}

.log-time {
  color: #666;
  font-size: 0.9em;
  min-width: 80px;
}

.log-message {
  flex: 1;
}

.log-entry.success .log-message {
  color: #51cf66;
}

.log-entry.error .log-message {
  color: #ff6b6b;
}

.log-entry.warning .log-message {
  color: #ffd43b;
}

.log-entry.info .log-message {
  color: #74c0fc;
}
</style>
EOF

# Create main App.vue
cat > src/App.vue << 'EOF'
<template>
  <div id="app">
    <JailbreakInterface />
  </div>
</template>

<script setup>
import JailbreakInterface from './components/JailbreakInterface.vue'
</script>

<style>
#app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #333;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}
</style>
EOF

# Create main.js
cat > src/main.js << 'EOF'
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
EOF

# Create index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TotallyNotSpyware v2 - PWA</title>
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="TNSv2">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="theme-color" content="#000000">
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

# Install additional dependencies
echo "📥 Installing additional PWA dependencies..."
npm install vite-plugin-pwa workbox-window

# Create build script
cat > build-pwa.sh << 'EOF'
#!/bin/bash

echo "🔨 Building PWA for production..."

# Build the PWA
npm run build

# Copy additional assets
echo "📦 Copying additional assets..."
cp -r ../stages/* dist/stages/ 2>/dev/null || true
cp -r ../icons dist/ 2>/dev/null || true

echo "✅ PWA built successfully!"
echo "📁 Output directory: dist/"
echo ""
echo "🚀 To serve the PWA:"
echo "   cd dist && python3 -m http.server 8000"
echo ""
echo "📱 To test PWA installation:"
echo "   1. Open http://localhost:8000 in Chrome/Edge"
echo "   2. Look for the install prompt"
echo "   3. Or use 'Add to Home Screen' in mobile browsers"
EOF

chmod +x build-pwa.sh

# Create development script
cat > dev-pwa.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting PWA development server..."

# Check if we have the required files
if [ ! -f "public/index.html" ]; then
    echo "❌ Required files not found. Run setup-pwa-scaffold.sh first."
    exit 1
fi

# Start development server
npm run dev
EOF

chmod +x dev-pwa.sh

echo ""
echo "🎉 PWA scaffold setup completed!"
echo ""
echo "📁 PWA scaffold directory: $PWA_DIR"
echo ""
echo "🚀 Next steps:"
echo "   1. Navigate to PWA scaffold: cd $PWA_DIR"
echo "   2. Start development server: ./dev-pwa.sh"
echo "   3. Build for production: ./build-pwa.sh"
echo ""
echo "🔧 Available commands:"
echo "   npm run dev      - Start development server"
echo "   npm run build    - Build for production"
echo "   npm run preview  - Preview production build"
echo ""
echo "📱 Your PWA is now ready with:"
echo "   - Vue 3 + Vite build system"
echo "   - PWA plugin with service worker"
echo "   - Modern UI components"
echo "   - Jailbreak interface integration"
echo "   - Hot module replacement for development"
