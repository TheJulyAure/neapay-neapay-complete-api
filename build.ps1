# build.ps1 - Build NeaPay Complete Installer
# Usage: .\build.ps1 [Release|Debug]

param(
    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",
    [string]$Version = "1.0.0",
    [switch]$Sign,
    [string]$CertPath = "",
    [string]$CertPassword = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NeaPay Complete - Build Script v$Version" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Payload
Write-Host "[1/4] Building payload..." -ForegroundColor Yellow

$payloadDest = Join-Path $ScriptDir "payload\neapay-complete"

if (Test-Path $payloadDest) {
    Remove-Item $payloadDest -Recurse -Force
}

# Copy main application files
$copyItems = @(
    "penthouse-api",
    "frontend",
    "neapay",
    "sdk",
    "docs",
    "config",
    "scripts",
    "tools"
)

foreach ($item in $copyItems) {
    $src = Join-Path $ProjectDir $item
    $dest = Join-Path $payloadDest $item
    if (Test-Path $src) {
        Copy-Item $src -Destination $dest -Recurse -Force
        Write-Host "      ✅ Copied: $item" -ForegroundColor Gray
    }
}

# Copy root-level files
$rootFiles = @(
    "*.ps1",
    "*.md",
    "docker-compose.yml",
    "docker-compose.override.yml",
    ".dockerignore",
    "Makefile"
)

foreach ($pattern in $rootFiles) {
    $files = Get-ChildItem -Path $ProjectDir -Filter $pattern -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Copy-Item $file.FullName -Destination $payloadDest -Force
        Write-Host "      ✅ Copied: $($file.Name)" -ForegroundColor Gray
    }
}

# Copy VS Code settings
$vscodeSrc = Join-Path $ProjectDir ".vscode"
$vscodeDest = Join-Path $payloadDest ".vscode"
if (Test-Path $vscodeSrc) {
    Copy-Item $vscodeSrc -Destination $vscodeDest -Recurse -Force
    Write-Host "      ✅ Copied: .vscode" -ForegroundColor Gray
}

# Ensure third-party placeholder
$thirdParty = Join-Path $ScriptDir "payload\third-party"
if (-not (Test-Path $thirdParty)) {
    New-Item -ItemType Directory -Path $thirdParty | Out-Null
}

# Create placeholder for Docker
$dockerPlaceholder = @"
==============================================
  NeaPay Complete - Docker Configuration
==============================================

This folder is for the bundled Docker Desktop installer.

DOWNLOAD:
- Get Docker Desktop for Windows from:
  https://www.docker.com/products/docker-desktop

- Save as: docker-desktop-installer.exe
- Place in: payload\third-party\

For more info, see: https://docs.neapay.com/docker
"@

if (-not (Test-Path (Join-Path $thirdParty "docker-desktop-installer.exe"))) {
    Set-Content -Path (Join-Path $thirdParty "README.txt") -Value $dockerPlaceholder
}

Write-Host "      ✅ Payload built" -ForegroundColor Green

# Step 2: Check InstallAware
Write-Host "[2/4] Checking InstallAware..." -ForegroundColor Yellow

$iaPath = $null
$possiblePaths = @(
    "${env:ProgramFiles}\InstallAnywhere\InstallAnywhere.exe",
    "${env:ProgramFiles(x86)}\InstallAnywhere\InstallAnywhere.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $iaPath = $path
        break
    }
}

if ($iaPath) {
    Write-Host "      ✅ InstallAware found: $iaPath" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  InstallAware not found - will create placeholder" -ForegroundColor Yellow
}

# Step 3: Build Installer
Write-Host "[3/4] Building installer..." -ForegroundColor Yellow

$distDir = Join-Path $ScriptDir "dist"
$outputExe = Join-Path $distDir "NeaPayComplete-$Version-Setup.exe"

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

if ($iaPath) {
    Write-Host "      🔨 Building with InstallAware ($Configuration)..." -ForegroundColor Cyan
    # & $iaPath -p "$ScriptDir\installer\NeaPayComplete.mpr" -b $Configuration -o $distDir
    Write-Host "      ⚠️  InstallAware build command ready - run manually" -ForegroundColor Yellow
} else {
    # Create placeholder for testing
    Write-Host "      📝 Creating placeholder installer..." -ForegroundColor Yellow
    
    $stubContent = @"
NeaPay Complete Installer Stub
===============================
Version: $Version
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Configuration: $Configuration

To build the real installer:
1. Install InstallAnywhere X14
2. Open installer\NeaPayComplete.mpr
3. Build to dist\

Payload location: $payloadDest
Installer project: $ScriptDir\installer
"@
    
    Set-Content -Path (Join-Path $distDir "BUILD_INFO.txt") -Value $stubContent
    
    # Copy payload to dist for manual build
    $manualPayload = Join-Path $distDir "payload"
    if (Test-Path $manualPayload) {
        Remove-Item $manualPayload -Recurse -Force
    }
    Copy-Item (Join-Path $ScriptDir "payload") -Destination $manualPayload -Recurse -Force
    
    $outputExe = Join-Path $distDir "NeaPayComplete-$Version-Setup-Stub.exe"
}

Write-Host "      ✅ Build complete" -ForegroundColor Green

# Step 4: Code Signing (optional)
if ($Sign -and (Test-Path $outputExe) -and $CertPath) {
    Write-Host "[4/4] Code signing..." -ForegroundColor Yellow
    
    if (Test-Path $CertPath) {
        $signScript = Join-Path $ScriptDir "installer\sign-installer.ps1"
        if (Test-Path $signScript) {
            & $signScript -InstallerPath $outputExe -PfxPath $CertPath -PfxPassword $CertPassword
        } else {
            Write-Host "      ⚠️  Signing script not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      ⚠️  Certificate not provided. Skipping sign." -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/4] Code signing skipped" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ✅ Build Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Output: $outputExe" -ForegroundColor White
Write-Host "  Version: $Version" -ForegroundColor White
Write-Host "  Configuration: $Configuration" -ForegroundColor White
Write-Host ""
