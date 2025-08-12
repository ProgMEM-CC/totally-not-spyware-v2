#!/bin/bash

# TotallyNotSpyware v2 - iOS Wrapper Setup
# This script sets up the iOS wrapper using PWABuilder's iOS App Store tools

set -e

echo "📱 Setting up iOS wrapper for TotallyNotSpyware v2..."

# Check if we're in the right directory
if [ ! -f "manifest.json" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Check if we have the PWA scaffold
if [ ! -d "tns-pwa" ]; then
    echo "❌ PWA scaffold not found. Run setup-pwa-scaffold.sh first."
    exit 1
fi

# Check if we have a built PWA
if [ ! -d "tns-pwa/dist" ]; then
    echo "⚠️  PWA not built yet. Building first..."
    cd tns-pwa
    ./build-pwa.sh
    cd ..
fi

# Create iOS wrapper directory
IOS_WRAPPER_DIR="ios-wrapper"
if [ -d "$IOS_WRAPPER_DIR" ]; then
    echo "⚠️  iOS wrapper directory already exists. Removing..."
    rm -rf "$IOS_WRAPPER_DIR"
fi

echo "📦 Setting up iOS wrapper environment..."

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✅ Running on macOS - can build iOS wrapper directly"
    CAN_BUILD_IOS=true
else
    echo "⚠️  Not on macOS - will set up wrapper for CI/CD build"
    CAN_BUILD_IOS=false
fi

# Create iOS wrapper structure
mkdir -p "$IOS_WRAPPER_DIR"
cd "$IOS_WRAPPER_DIR"

# Create Xcode project structure
echo "📁 Creating Xcode project structure..."

# Create project directory
mkdir -p "TotallyNotSpyware"
cd "TotallyNotSpyware"

# Create main app files
cat > "AppDelegate.swift" << 'EOF'
import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
}
EOF

cat > "ViewController.swift" << 'EOF'
import UIKit
import WebKit

class ViewController: UIViewController {
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPWA()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Setup web view
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(webView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup navigation bar
        navigationItem.title = "TotallyNotSpyware v2"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    private func loadPWA() {
        // Load the PWA from local bundle
        if let pwaURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PWA") {
            webView.loadFileURL(pwaURL, allowingReadAccessTo: pwaURL.deletingLastPathComponent())
        } else {
            // Fallback to remote URL (for development)
            let fallbackURL = URL(string: "https://your-pwa-domain.com")!
            webView.load(URLRequest(url: fallbackURL))
        }
    }
    
    @objc private func refreshTapped() {
        webView.reload()
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(1.0, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.progressView.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to load PWA: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
EOF

# Create Info.plist
cat > "Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>TotallyNotSpyware v2</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
EOF

# Create project.pbxproj
cat > "project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		A1234567890123456789012A /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1234567890123456789012B /* AppDelegate.swift */; };
		A1234567890123456789012C /* ViewController.swift in Sources */ = {isa = PBXBuildFile; fileRef = A1234567890123456789012D /* ViewController.swift */; };
		A1234567890123456789012E /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = A1234567890123456789012F /* Assets.xcassets */; };
		A1234567890123456789013A /* LaunchScreen.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = A1234567890123456789013B /* LaunchScreen.storyboard */; };
		A1234567890123456789013C /* PWA in Resources */ = {isa = PBXBuildFile; fileRef = A1234567890123456789013D /* PWA */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		A1234567890123456789012A /* TotallyNotSpyware.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TotallyNotSpyware.app; sourceTree = BUILT_PRODUCTS_DIR; };
		A1234567890123456789012B /* AppDelegate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		A1234567890123456789012C /* ViewController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ViewController.swift; sourceTree = "<group>"; };
		A1234567890123456789012D /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		A1234567890123456789012E /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		A1234567890123456789012F /* LaunchScreen.storyboard */ = {isa = PBXFileReference; lastKnownFileType = file.storyboard; path = LaunchScreen.storyboard; sourceTree = "<group>"; };
		A1234567890123456789013A /* PWA */ = {isa = PBXFileReference; lastKnownFileType = folder; path = PWA; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		A1234567890123456789012B /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		A1234567890123456789012C /* TotallyNotSpyware */ = {
			isa = PBXGroup;
			children = (
				A1234567890123456789012B /* AppDelegate.swift */,
				A1234567890123456789012C /* ViewController.swift */,
				A1234567890123456789012D /* Info.plist */,
				A1234567890123456789012E /* Assets.xcassets */,
				A1234567890123456789012F /* LaunchScreen.storyboard */,
				A1234567890123456789013A /* PWA */,
			);
			path = TotallyNotSpyware;
			sourceTree = "<group>";
		};
		A1234567890123456789012D /* Products */ = {
			isa = PBXGroup;
			children = (
				A1234567890123456789012A /* TotallyNotSpyware.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		A1234567890123456789012E = {
			isa = PBXGroup;
			children = (
				A1234567890123456789012C /* TotallyNotSpyware */,
				A1234567890123456789012D /* Products */,
			);
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		A1234567890123456789012F /* TotallyNotSpyware */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = A1234567890123456789013B /* Build configuration list for PBXNativeTarget "TotallyNotSpyware" */;
			buildPhases = (
				A1234567890123456789012C /* Sources */,
				A1234567890123456789012B /* Frameworks */,
				A1234567890123456789012D /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TotallyNotSpyware;
			productName = TotallyNotSpyware;
			productReference = A1234567890123456789012A /* TotallyNotSpyware.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		A1234567890123456789013C /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {
					A1234567890123456789012F = {
						CreatedOnToolsVersion = 15.0;
					};
				};
			};
			buildConfigurationList = A1234567890123456789013D /* Build configuration list for PBXProject "TotallyNotSpyware" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = A1234567890123456789012E;
			productRefGroup = A1234567890123456789012D /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				A1234567890123456789012F /* TotallyNotSpyware */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		A1234567890123456789012D /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A1234567890123456789012E /* Assets.xcassets in Resources */,
				A1234567890123456789012F /* LaunchScreen.storyboard in Resources */,
				A1234567890123456789013A /* PWA in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		A1234567890123456789012C /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A1234567890123456789012A /* AppDelegate.swift in Sources */,
				A1234567890123456789012B /* ViewController.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		A1234567890123456789013E /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		A1234567890123456789013F /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		A1234567890123456789014A /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = TotallyNotSpyware/Info.plist;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.totallynotspyware.v2;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Debug;
		};
		A1234567890123456789014B /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = TotallyNotSpyware/Info.plist;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.totallynotspyware.v2;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		A1234567890123456789013B /* Build configuration list for PBXNativeTarget "TotallyNotSpyware" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A1234567890123456789014A /* Debug */,
				A1234567890123456789014B /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A1234567890123456789013D /* Build configuration list for PBXProject "TotallyNotSpyware" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A1234567890123456789013E /* Debug */,
				A1234567890123456789013F /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = A1234567890123456789013C /* Project object */;
}
EOF

# Create workspace file
cat > "TotallyNotSpyware.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:TotallyNotSpyware.xcodeproj">
   </FileRef>
</Workspace>
EOF

# Create project file
cat > "TotallyNotSpyware.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF

# Copy PWA files
echo "📦 Copying PWA files to iOS wrapper..."
mkdir -p "TotallyNotSpyware/PWA"
cp -r ../../tns-pwa/dist/* "TotallyNotSpyware/PWA/"

# Create build scripts
echo "🔨 Creating build scripts..."

cat > "build-ios.sh" << 'EOF'
#!/bin/bash

echo "🔨 Building iOS wrapper..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

# Build the project
echo "📱 Building iOS app..."
xcodebuild \
    -workspace TotallyNotSpyware.xcworkspace \
    -scheme TotallyNotSpyware \
    -configuration Release \
    -archivePath build/TotallyNotSpyware.xcarchive \
    -derivedDataPath build/DerivedData \
    build archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    echo "📁 Archive location: build/TotallyNotSpyware.xcarchive"
else
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🚀 Next steps:"
echo "   1. Open TotallyNotSpyware.xcworkspace in Xcode"
echo "   2. Configure your development team and bundle identifier"
echo "   3. Archive and export for App Store distribution"
EOF

chmod +x build-ios.sh

# Create export options plist
cat > "exportOptions.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

# Create GitHub Actions workflow
mkdir -p ".github/workflows"
cat > ".github/workflows/ios-build.yml" << 'EOF'
name: iOS Wrapper Build

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'
          
      - name: Install dependencies
        run: |
          sudo gem install cocoapods
          cd ios-wrapper/TotallyNotSpyware
          pod install --repo-update || true
          
      - name: Build iOS app
        run: |
          cd ios-wrapper
          xcodebuild \
            -workspace TotallyNotSpyware.xcworkspace \
            -scheme TotallyNotSpyware \
            -configuration Release \
            -archivePath $PWD/build/TotallyNotSpyware.xcarchive \
            -derivedDataPath $PWD/build/DerivedData \
            CODE_SIGN_STYLE=Manual \
            PROVISIONING_PROFILE_SPECIFIER="${{ secrets.SPYWRAP_PROFILE }}" \
            build archive
            
      - name: Export IPA
        run: |
          cd ios-wrapper
          xcodebuild -exportArchive \
            -archivePath $PWD/build/TotallyNotSpyware.xcarchive \
            -exportOptionsPlist exportOptions.plist \
            -exportPath $PWD/build \
            -allowProvisioningUpdates
            
      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: TotallyNotSpyware-v2-ipa
          path: ios-wrapper/build/*.ipa
          
      - name: Upload archive artifact
        uses: actions/upload-artifact@v4
        with:
          name: TotallyNotSpyware-v2-archive
          path: ios-wrapper/build/TotallyNotSpyware.xcarchive
          
      - name: Build summary
        run: |
          echo "## 🎉 iOS Build Complete!" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Build Status:** ✅ Success" >> $GITHUB_STEP_SUMMARY
          echo "**Platform:** iOS 12.0+" >> $GITHUB_STEP_SUMMARY
          echo "**Target:** iPhone/iPad" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Artifacts:**" >> $GITHUB_STEP_SUMMARY
          echo "- IPA file for distribution" >> $GITHUB_STEP_SUMMARY
          echo "- Xcode archive for debugging" >> $GITHUB_STEP_SUMMARY
EOF

# Create README for iOS wrapper
cat > "README.md" << 'EOF'
# TotallyNotSpyware v2 - iOS Wrapper

This is the iOS native wrapper for the TotallyNotSpyware v2 PWA, enabling App Store distribution.

## 📱 Features

- **Native iOS App** - Wraps the PWA in a native iOS container
- **WebView Integration** - Uses WKWebView to display the PWA
- **App Store Ready** - Configured for App Store submission
- **iOS 12+ Support** - Targets iOS 12.0 and later
- **Universal App** - Supports both iPhone and iPad

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 15.0+
- Apple Developer Account
- iOS Development Certificate
- Provisioning Profile

### Building

1. **Open the project:**
   ```bash
   open TotallyNotSpyware.xcworkspace
   ```

2. **Configure signing:**
   - Select your development team
   - Update bundle identifier if needed
   - Ensure provisioning profile is set

3. **Build and run:**
   - Select target device/simulator
   - Press Cmd+R to build and run

### Command Line Build

```bash
# Build archive
./build-ios.sh

# Or manually
xcodebuild -workspace TotallyNotSpyware.xcworkspace \
  -scheme TotallyNotSpyware \
  -configuration Release \
  -archivePath build/TotallyNotSpyware.xcarchive \
  build archive
```

## 🔧 Configuration

### Bundle Identifier
Update `PRODUCT_BUNDLE_IDENTIFIER` in the project settings:
```
com.yourcompany.totallynotspyware
```

### Development Team
Set your development team ID in the project settings or use:
```bash
xcodebuild -workspace TotallyNotSpyware.xcworkspace \
  -scheme TotallyNotSpyware \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

### PWA Source
The PWA files are located in `TotallyNotSpyware/PWA/`. To update:
1. Rebuild the PWA: `cd ../tns-pwa && ./build-pwa.sh`
2. Copy new files: `cp -r dist/* ../ios-wrapper/TotallyNotSpyware/PWA/`

## 📦 Distribution

### App Store Distribution
1. Archive the project in Xcode
2. Use Organizer to export for App Store
3. Upload via App Store Connect

### Ad Hoc Distribution
1. Archive the project
2. Export with "Ad Hoc" method
3. Distribute IPA file to test devices

### Enterprise Distribution
1. Archive the project
2. Export with "Enterprise" method
3. Host IPA file on your enterprise server

## 🔒 Security Considerations

- **Code Signing** - Required for distribution
- **App Transport Security** - Configured to allow local content
- **Sandboxing** - Runs in iOS app sandbox
- **Entitlements** - Minimal required entitlements

## 🐛 Troubleshooting

### Common Issues

1. **Code Signing Errors:**
   - Verify development team is set
   - Check provisioning profile validity
   - Ensure certificates are not expired

2. **Build Failures:**
   - Clean build folder (Cmd+Shift+K)
   - Check deployment target compatibility
   - Verify all required files are present

3. **PWA Loading Issues:**
   - Check PWA files are copied correctly
   - Verify file paths in ViewController
   - Test PWA independently first

### Debug Commands

```bash
# Clean build
xcodebuild clean -workspace TotallyNotSpyware.xcworkspace

# Show build settings
xcodebuild -workspace TotallyNotSpyware.xcworkspace \
  -scheme TotallyNotSpyware \
  -showBuildSettings

# Build with verbose output
xcodebuild -workspace TotallyNotSpyware.xcworkspace \
  -scheme TotallyNotSpyware \
  -configuration Debug \
  build -verbose
```

## 📚 Resources

- [Apple Developer Documentation](https://developer.apple.com/)
- [WKWebView Guide](https://developer.apple.com/documentation/webkit/wkwebview)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on device
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
EOF

cd ..

echo ""
echo "🎉 iOS wrapper setup completed!"
echo ""
echo "📁 iOS wrapper directory: $IOS_WRAPPER_DIR"
echo ""
echo "🚀 Next steps:"
echo "   1. Navigate to iOS wrapper: cd $IOS_WRAPPER_DIR"
echo "   2. Open project in Xcode: open TotallyNotSpyware.xcworkspace"
echo "   3. Configure signing and bundle identifier"
echo "   4. Build and test on device"
echo ""
echo "🔧 Available commands:"
echo "   ./build-ios.sh      - Build iOS app (macOS only)"
echo "   open *.xcworkspace  - Open in Xcode"
echo ""
echo "📱 Your iOS wrapper is now ready with:"
echo "   - Native iOS app structure"
echo "   - WKWebView integration"
echo "   - App Store configuration"
echo "   - CI/CD workflow setup"
echo "   - Comprehensive documentation"
echo ""
echo "⚠️  Note: iOS builds require macOS with Xcode"
echo "   For CI/CD, use the provided GitHub Actions workflow"
