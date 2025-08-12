#!/bin/bash

# TotallyNotSpyware v2 - WSL2 Development Environment Setup
# This script sets up the development environment for iOS 12 Chimera jailbreak development

set -e

echo "🔧 Setting up WSL2 development environment for TotallyNotSpyware v2..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential build tools
echo "🔨 Installing essential build tools..."
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    libbz2-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    libtiff5-dev \
    libopenjp2-7-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    libxrandr-dev \
    libxss-dev \
    libxtst-dev \
    libxext-dev \
    libxrender-dev \
    libxinerama-dev \
    libxi-dev \
    libxfixes-dev \
    libxdamage-dev \
    libxcomposite-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxss-dev \
    libxtst-dev \
    libxext-dev \
    libxrender-dev \
    libxinerama-dev \
    libxi-dev \
    libxfixes-dev \
    libxdamage-dev \
    libxcomposite-dev \
    libxcursor-dev

# Install Node.js and npm (for PWA development)
echo "📱 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip3 install --user -r requirements.txt

# Install Theos (iOS development framework)
echo "📱 Installing Theos..."
git clone --recursive https://github.com/theos/theos.git $THEOS
echo 'export THEOS=~/theos' >> ~/.bashrc
echo 'export PATH=$THEOS/bin:$PATH' >> ~/.bashrc

# Install Xtools (iOS toolchain)
echo "🔧 Installing Xtools..."
mkdir -p ~/xtools
cd ~/xtools

# Download and install Xtools
wget https://github.com/wh1te4ever/xtools/releases/latest/download/xtools-linux.tar.gz
tar -xzf xtools-linux.tar.gz
echo 'export PATH=~/xtools/bin:$PATH' >> ~/.bashrc

# Install additional iOS development tools
echo "📱 Installing additional iOS development tools..."

# Install ldid (for code signing)
git clone https://github.com/ProcursusTeam/ldid.git
cd ldid
make
sudo cp ldid /usr/local/bin/
cd ..

# Install jtool2 (for Mach-O manipulation)
git clone https://github.com/keith-jmach/jtool2.git
cd jtool2
make
sudo cp jtool2 /usr/local/bin/
cd ..

# Install ios-deploy (for device deployment)
npm install -g ios-deploy

# Install libimobiledevice tools
sudo apt install -y \
    libimobiledevice6 \
    libimobiledevice-utils \
    libimobiledevice-glue-dev \
    libplist-dev \
    libusbmuxd-dev

# Install additional development libraries
sudo apt install -y \
    libcurl4-openssl-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libgif-dev \
    libwebp-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libass-dev \
    libbluray-dev \
    libdav1d-dev \
    libmp3lame-dev \
    libopus-dev \
    libvorbis-dev \
    libvpx-dev \
    libx264-dev \
    libx265-dev \
    libxvid-dev

# Create development directory structure
echo "📁 Creating development directory structure..."
mkdir -p ~/ios-dev/{projects,binaries,scripts,tools}

# Install additional Python packages for development
echo "🐍 Installing additional Python development packages..."
pip3 install --user \
    ipython \
    jupyter \
    pytest \
    black \
    flake8 \
    mypy \
    requests \
    beautifulsoup4 \
    lxml \
    pillow \
    numpy \
    pandas

# Install additional Node.js packages for PWA development
echo "📱 Installing additional Node.js packages for PWA development..."
npm install -g \
    @vue/cli \
    @angular/cli \
    create-react-app \
    typescript \
    webpack \
    webpack-cli \
    webpack-dev-server \
    babel-loader \
    @babel/core \
    @babel/preset-env \
    css-loader \
    style-loader \
    html-webpack-plugin \
    clean-webpack-plugin \
    workbox-webpack-plugin

# Create a virtual environment for the project
echo "🐍 Creating Python virtual environment..."
cd ~/totally-not-spyware-v2
python3 -m venv venv
echo 'source ~/totally-not-spyware-v2/venv/bin/activate' >> ~/.bashrc

# Install project dependencies in virtual environment
source venv/bin/activate
pip install -r requirements.txt

# Create development configuration
echo "⚙️ Creating development configuration..."
cat > ~/.ios-dev-config << EOF
# iOS Development Configuration
export THEOS=~/theos
export PATH=\$THEOS/bin:\$PATH
export PATH=~/xtools/bin:\$PATH
export PATH=~/ios-dev/tools:\$PATH

# iOS SDK paths (adjust as needed)
export IOS_SDK_PATH=\$THEOS/sdks/iPhoneOS.sdk
export IOS_SIMULATOR_SDK_PATH=\$THEOS/sdks/iPhoneSimulator.sdk

# Development tools
export LDID_PATH=/usr/local/bin/ldid
export JTOOL2_PATH=/usr/local/bin/jtool2

# Project paths
export PROJECT_ROOT=~/totally-not-spyware-v2
export DEV_BINARIES=~/ios-dev/binaries
export DEV_SCRIPTS=~/ios-dev/scripts
EOF

echo 'source ~/.ios-dev-config' >> ~/.bashrc

# Create useful development scripts
echo "📝 Creating development scripts..."
cat > ~/ios-dev/scripts/build-ios.sh << 'EOF'
#!/bin/bash
# Build script for iOS targets
set -e

echo "🔨 Building iOS target..."
cd ~/totally-not-spyware-v2

# Activate virtual environment
source venv/bin/activate

# Build the project
python3 stages/build.py

echo "✅ Build completed successfully!"
EOF

cat > ~/ios-dev/scripts/deploy-ios.sh << 'EOF'
#!/bin/bash
# Deploy script for iOS devices
set -e

echo "📱 Deploying to iOS device..."
cd ~/totally-not-spyware-v2

# Activate virtual environment
source venv/bin/activate

# Check if device is connected
if ! idevice_id -l | grep -q .; then
    echo "❌ No iOS device connected!"
    exit 1
fi

# Deploy the project
python3 release.py

echo "✅ Deployment completed successfully!"
EOF

cat > ~/ios-dev/scripts/dev-server.sh << 'EOF'
#!/bin/bash
# Development server script
set -e

echo "🚀 Starting development server..."
cd ~/totally-not-spyware-v2

# Activate virtual environment
source venv/bin/activate

# Start the development server
python3 server.py
EOF

# Make scripts executable
chmod +x ~/ios-dev/scripts/*.sh

# Create shortcuts
echo "🔗 Creating shortcuts..."
echo 'alias build-ios="~/ios-dev/scripts/build-ios.sh"' >> ~/.bashrc
echo 'alias deploy-ios="~/ios-dev/scripts/deploy-ios.sh"' >> ~/.bashrc
echo 'alias dev-server="~/ios-dev/scripts/dev-server.sh"' >> ~/.bashrc
echo 'alias ios-dev="cd ~/ios-dev"' >> ~/.bashrc
echo 'alias tns="cd ~/totally-not-spyware-v2"' >> ~/.bashrc

# Install additional useful tools
echo "🛠️ Installing additional useful tools..."

# Install tmux for development sessions
sudo apt install -y tmux

# Install htop for system monitoring
sudo apt install -y htop

# Install tree for directory visualization
sudo apt install -y tree

# Install ripgrep for fast searching
sudo apt install -y ripgrep

# Install fd for fast file finding
sudo apt install -y fd-find

# Install bat for better cat
sudo apt install -y bat

# Install exa for better ls
sudo apt install -y exa

# Install fzf for fuzzy finding
sudo apt install -y fzf

# Install zsh and oh-my-zsh (optional)
echo "🐚 Installing Zsh and Oh-My-Zsh..."
sudo apt install -y zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Create a custom zsh theme for iOS development
cat > ~/.oh-my-zsh/custom/themes/ios-dev.zsh-theme << 'EOF'
# iOS Development Theme for Oh-My-Zsh
PROMPT='%{$fg[red]%}🔓%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:%{$fg[yellow]%}%~%{$reset_color%}$(git_prompt_info)
%{$fg[red]%}➤%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
EOF

# Set zsh as default shell
chsh -s $(which zsh)

# Final setup
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Navigate to your project: cd ~/totally-not-spyware-v2"
echo "3. Activate virtual environment: source venv/bin/activate"
echo "4. Start development server: python3 server.py"
echo ""
echo "🚀 Useful commands:"
echo "  build-ios    - Build iOS target"
echo "  deploy-ios   - Deploy to iOS device"
echo "  dev-server   - Start development server"
echo "  ios-dev      - Navigate to iOS development directory"
echo "  tns          - Navigate to project directory"
echo ""
echo "📱 Your PWA is now ready for iOS 12 Chimera development!"
echo "🔧 Development environment includes: Theos, Xtools, and all necessary tools"
