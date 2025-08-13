# Build iOS IPA for TotallyNotSpyware v2
# This script builds the iOS wrapper into an IPA file

param(
    [string]$Configuration = "Release",
    [string]$Scheme = "TotallyNotSpyware",
    [string]$Workspace = "TotallyNotSpyware.xcworkspace",
    [string]$Project = "TotallyNotSpyware.xcodeproj"
)

Write-Host "📱 Building iOS IPA for TotallyNotSpyware v2..." -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "ios-wrapper")) {
    Write-Host "❌ iOS wrapper directory not found. Run setup-ios-wrapper.sh first." -ForegroundColor Red
    exit 1
}

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

# Navigate to iOS wrapper directory
Set-Location "ios-wrapper"

# Check if we have Xcode project files
if (-not (Test-Path "TotallyNotSpyware")) {
    Write-Host "❌ iOS wrapper project not found. Run setup-ios-wrapper.sh first." -ForegroundColor Red
    exit 1
}

Set-Location "TotallyNotSpyware"

# Check if we have a workspace or project
$hasWorkspace = Test-Path $Workspace
$hasProject = Test-Path $Project

if (-not $hasWorkspace -and -not $hasProject) {
    Write-Host "❌ No Xcode project or workspace found." -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Checking available schemes..." -ForegroundColor Yellow

# List available schemes
if ($hasWorkspace) {
    try {
        $schemes = xcodebuild -workspace $Workspace -list -json | ConvertFrom-Json
        Write-Host "Available schemes: $($schemes.project.schemes -join ', ')" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not list schemes. Continuing with default..." -ForegroundColor Yellow
    }
} else {
    try {
        $schemes = xcodebuild -project $Project -list -json | ConvertFrom-Json
        Write-Host "Available schemes: $($schemes.project.schemes -join ', ')" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not list schemes. Continuing with default..." -ForegroundColor Yellow
    }
}

# Create build directory
$buildDir = "build"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Write-Host "🏗️  Building archive..." -ForegroundColor Yellow

# Build archive
try {
    if ($hasWorkspace) {
        xcodebuild -workspace $Workspace -scheme $Scheme -configuration $Configuration -archivePath "$PWD/$buildDir/TotallyNotSpyware.xcarchive" build archive
    } else {
        xcodebuild -project $Project -scheme $Scheme -configuration $Configuration -archivePath "$PWD/$buildDir/TotallyNotSpyware.xcarchive" build archive
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Archive built successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Archive build failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create export options plist
$exportOptions = @"
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
"@

$exportOptions | Out-File -FilePath "$buildDir/exportOptions.plist" -Encoding UTF8

Write-Host "📦 Exporting IPA..." -ForegroundColor Yellow

# Export IPA
try {
    xcodebuild -exportArchive -archivePath "$PWD/$buildDir/TotallyNotSpyware.xcarchive" -exportOptionsPlist "$PWD/$buildDir/exportOptions.plist" -exportPath "$PWD/$buildDir"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ IPA exported successfully!" -ForegroundColor Green
        
        # Find the IPA file
        $ipaFile = Get-ChildItem -Path $buildDir -Filter "*.ipa" | Select-Object -First 1
        if ($ipaFile) {
            Write-Host "📱 IPA file: $($ipaFile.FullName)" -ForegroundColor Green
            Write-Host "📏 File size: $([math]::Round($ipaFile.Length / 1MB, 2)) MB" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ IPA export failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Export failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 iOS IPA build completed successfully!" -ForegroundColor Green
Write-Host "📁 Build files are in: $PWD/$buildDir" -ForegroundColor Green

# Return to original directory
Set-Location "../.."
