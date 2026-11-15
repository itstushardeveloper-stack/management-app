# ==========================================================
# Event & Venue Management System - APK Build Script
# ==========================================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Event & Venue Management - Android APK Builder" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check Flutter
$flutterPath = "C:\src\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterPath)) {
    $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        $flutterPath = $flutterCmd.Source
    } else {
        Write-Host "[ERROR] Flutter SDK not found in C:\src\flutter\bin or PATH." -ForegroundColor Red
        exit 1
    }
}
Write-Host "[OK] Flutter found at $flutterPath" -ForegroundColor Green

# 2. Check Java JDK
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Write-Host "[!] Java (JDK) is not installed." -ForegroundColor Yellow
    Write-Host "    Installing OpenJDK 17 via winget..." -ForegroundColor Yellow
    winget install Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "[OK] Java runtime found." -ForegroundColor Green
}

# 3. Check Android SDK
$androidSdk = $env:ANDROID_HOME
if (-not $androidSdk) {
    $androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
}

if (-not (Test-Path $androidSdk)) {
    Write-Host ""
    Write-Host "[!] Android SDK was not found at $androidSdk." -ForegroundColor Yellow
    Write-Host "    To build an Android APK, you need the Android SDK." -ForegroundColor Yellow
    Write-Host "    Please install Android Studio (which installs the Android SDK automatically):" -ForegroundColor Cyan
    Write-Host "      winget install Google.AndroidStudio" -ForegroundColor White
    Write-Host ""
    Write-Host "    Once installed, open Android Studio once to complete SDK setup, then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Android SDK located at $androidSdk" -ForegroundColor Green

# 4. Fetch packages & Build
Write-Host "[*] Resolving project dependencies (flutter pub get)..." -ForegroundColor Cyan
& $flutterPath pub get

Write-Host "[*] Compiling Android Release APK (flutter build apk --release)..." -ForegroundColor Cyan
& $flutterPath build apk --release

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    $fullApk = (Get-Item $apkPath).FullName
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] APK Built successfully!" -ForegroundColor Green
    Write-Host "File location: $fullApk" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Build finished but APK output file was not found." -ForegroundColor Red
}

