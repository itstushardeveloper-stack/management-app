<#
.SYNOPSIS
    Automated Flutter SDK Setup Script
    Event & Venue Management System
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Event & Venue Management System - Flutter Setup Assistant" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check if git is available
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Host "[!] Git is required but was not found. Please install Git for Windows first." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Git is installed." -ForegroundColor Green

# 2. Target installation directory for Flutter
$flutterInstallDir = "C:\src\flutter"
if (-not (Test-Path "C:\src")) {
    New-Item -ItemType Directory -Path "C:\src" -Force | Out-Null
}

$flutterBat = "$flutterInstallDir\bin\flutter.bat"
if (-not (Test-Path $flutterBat)) {
    if (Test-Path $flutterInstallDir) {
        Remove-Item -Recurse -Force $flutterInstallDir -ErrorAction SilentlyContinue
    }
    Write-Host "[*] Downloading Flutter SDK (shallow clone) to $flutterInstallDir..." -ForegroundColor Yellow
    git clone --depth 1 https://github.com/flutter/flutter.git -b stable $flutterInstallDir
} else {
    Write-Host "[OK] Flutter SDK already present at $flutterInstallDir" -ForegroundColor Green
}

# 3. Add to User PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterBin = "$flutterInstallDir\bin"
if ($userPath -notlike "*$flutterBin*") {
    Write-Host "[*] Adding Flutter bin to User PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
    $env:Path += ";$flutterBin"
    Write-Host "[OK] Added to PATH: $flutterBin" -ForegroundColor Green
} else {
    Write-Host "[OK] Flutter bin is already in PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "[*] Running flutter doctor..." -ForegroundColor Cyan
& $flutterBat doctor

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Setup complete! Next steps:" -ForegroundColor Green
Write-Host " 1. cd d:\management-app" -ForegroundColor White
Write-Host " 2. flutter pub get" -ForegroundColor White
Write-Host " 3. flutter run" -ForegroundColor White
Write-Host " 4. flutter build apk --release (to generate the Android APK)" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
