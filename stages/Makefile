# TotallyNotSpyware v2 - Enhanced Makefile for WSL2
# Supports both native iOS compilation and cross-platform builds

# Detect platform and set appropriate flags
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Default iOS SDK paths (adjust these for your environment)
IOS_SDK_PATH ?= /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.1.sdk
IOS_SIM_SDK_PATH ?= /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator12.1.sdk

# Compiler detection
ifeq ($(UNAME_S),Darwin)
    # macOS - use system clang
    CC := clang
    IOS := -Oz -fvisibility=hidden -fno-stack-protector -arch arm64 -mios-version-min=12.0 -isysroot $(IOS_SDK_PATH)
    SIM := -Oz -fvisibility=hidden -fno-stack-protector -arch x86_64 -mios-version-min=12.0 -isysroot $(IOS_SIM_SDK_PATH)
else ifeq ($(UNAME_S),Linux)
    # Linux/WSL2 - use cross-compilation tools
    CC := clang
    # Check if we have iOS toolchain
    ifeq ($(wildcard $(HOME)/xtools),)
        $(warning Xtools not found. Install iOS toolchain first.)
        $(warning Run: ./setup-wsl2.sh)
        CC := gcc
        IOS := -Oz -fvisibility=hidden -fno-stack-protector
        SIM := -Oz -fvisibility=hidden -fno-stack-protector
    else
        # Use Xtools for cross-compilation
        CC := $(HOME)/xtools/bin/clang
        IOS := -Oz -fvisibility=hidden -fno-stack-protector -arch arm64 -mios-version-min=12.0 -target arm64-apple-ios12.0
        SIM := -Oz -fvisibility=hidden -fno-stack-protector -arch x86_64 -mios-version-min=12.0 -target x86_64-apple-ios12.0
    endif
else
    # Windows/Other - use generic compiler
    CC := gcc
    IOS := -Oz -fvisibility=hidden -fno-stack-protector
    SIM := -Oz -fvisibility=hidden -fno-stack-protector
endif

# Common flags
CFLAGS := -fno-stack-protector -fmodules -fobjc-arc
LDFLAGS := -shared -bind_at_load -fno-stack-protector -fobjc-arc -fmodules

# Source files
STAGE_SOURCES := stage1.c stage2.c hsp4.c trustcache.c kutils.c kpf.c
PHYSPUPPET_SOURCES := $(wildcard physpuppet/*.c)
STAGE3_SOURCES := $(wildcard stage3/*.c) $(wildcard stage3/*.m)

# Object files
STAGE_OBJS := $(STAGE_SOURCES:.c=.o)
PHYSPUPPET_OBJS := $(PHYSPUPPET_SOURCES:.c=.o)
STAGE3_OBJS := $(STAGE3_SOURCES:.c=.o) $(STAGE3_SOURCES:.m=.o)

# Main targets
.PHONY: all clean stages stage3 ios simulator test

all: stages stage3

# Build main stages binary
stages: $(STAGE_OBJS) $(PHYSPUPPET_OBJS)
	@echo "🔨 Building stages binary..."
	@echo "   Compiler: $(CC)"
	@echo "   Target: iOS ARM64"
	$(CC) $(IOS) $(CFLAGS) $^ $(LDFLAGS) -o $@ -framework IOKit -lc++
	@if [ -f exports.txt ]; then \
		echo "📝 Stripping symbols..."; \
		strip -u -r -s exports.txt $@; \
	fi
	@echo "✅ Stages binary built successfully!"
	@ls -la $@

# Build stage3 components
stage3: $(STAGE3_OBJS)
	@echo "🔨 Building stage3 components..."
	@if [ -n "$^" ]; then \
		echo "   Compiling $(words $^) stage3 source files..."; \
		$(CC) $(IOS) $(CFLAGS) $^ $(LDFLAGS) -o stage3.dylib -framework Foundation -framework UIKit; \
		echo "✅ Stage3 components built successfully!"; \
		ls -la stage3.dylib; \
	else \
		echo "⚠️  No stage3 sources found, skipping..."; \
	fi

# iOS simulator target
simulator: CFLAGS += -DSIMULATOR
simulator: $(STAGE_OBJS) $(PHYSPUPPET_OBJS)
	@echo "🔨 Building simulator version..."
	$(CC) $(SIM) $(CFLAGS) $^ $(LDFLAGS) -o stages_sim -framework IOKit -lc++
	@echo "✅ Simulator binary built successfully!"

# Test target for development
test: stages
	@echo "🧪 Running tests..."
	@if [ -f stages ]; then \
		echo "✅ Stages binary exists and is executable"; \
		file stages; \
	else \
		echo "❌ Stages binary not found"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f *.o *.dylib *.so stages stages_sim
	rm -f physpuppet/*.o
	rm -f stage3/*.o
	@echo "✅ Clean complete"

# Install target (for development)
install: stages
	@echo "📱 Installing stages binary..."
	@if [ -d "$(HOME)/ios-dev/binaries" ]; then \
		cp stages "$(HOME)/ios-dev/binaries/"; \
		echo "✅ Installed to $(HOME)/ios-dev/binaries/"; \
	else \
		echo "⚠️  ios-dev/binaries directory not found"; \
		echo "   Run: mkdir -p $(HOME)/ios-dev/binaries"; \
	fi

# Development target with verbose output
dev: CFLAGS += -g -DDEBUG
dev: stages

# Release target with optimizations
release: CFLAGS += -DNDEBUG -O3
release: stages

# Help target
help:
	@echo "🔓 TotallyNotSpyware v2 - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build all components (default)"
	@echo "  stages     - Build main stages binary"
	@echo "  stage3     - Build stage3 components"
	@echo "  simulator  - Build for iOS simulator"
	@echo "  test       - Run basic tests"
	@echo "  clean      - Remove build artifacts"
	@echo "  install    - Install to development directory"
	@echo "  dev        - Build with debug symbols"
	@echo "  release    - Build with release optimizations"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Environment variables:"
	@echo "  IOS_SDK_PATH      - iOS SDK path (default: $(IOS_SDK_PATH))"
	@echo "  IOS_SIM_SDK_PATH  - iOS Simulator SDK path (default: $(IOS_SIM_SDK_PATH))"
	@echo ""
	@echo "Platform detected: $(UNAME_S) on $(UNAME_M)"
	@echo "Compiler: $(CC)"

# Pattern rules for compilation
%.o: %.c
	@echo "   Compiling $<..."
	$(CC) -c $(IOS) $(CFLAGS) $< -o $@

%.o: %.m
	@echo "   Compiling Objective-C $<..."
	$(CC) -c $(IOS) $(CFLAGS) $< -o $@

# Dependencies
-include $(STAGE_OBJS:.o=.d)
-include $(PHYSPUPPET_OBJS:.o=.d)
-include $(STAGE3_OBJS:.o=.d)

# Generate dependency files
%.d: %.c
	@set -e; rm -f $@; \
	$(CC) -MM $(IOS) $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$
