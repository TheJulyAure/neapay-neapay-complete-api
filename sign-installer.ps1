param(
    [string]$InstallerPath = "dist\NeaPayComplete-1.0.0-Setup.exe",
    [string]$PfxPath = "certs\NeaPayCodeSign.pfx",
    [string]$PfxPassword = "",
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

# Validate parameters
if (-not (Test-Path $InstallerPath)) {
    Write-Error "Installer not found: $InstallerPath"
    exit 1
}

if (-not (Test-Path $PfxPath)) {
    Write-Error "Certificate not found: $PfxPath"
    Write-Host "Usage: sign-installer.ps1 -PfxPath 'certs\NeaPayCodeSign.pfx' -PfxPassword 'your-password'"
    exit 1
}

# Find signtool
$signtool = "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\signtool.exe"
if (-not (Test-Path $signtool)) {
    $signtool = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Windows Kits" -Recurse -Filter "signtool.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $signtool) {
        Write-Error "signtool.exe not found. Install Windows SDK."
        exit 1
    }
    $signtool = $signtool.FullName
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Code Signing NeaPay Complete Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Installer: $InstallerPath"
Write-Host "  Certificate: $PfxPath"
Write-Host "  Timestamp: $TimestampUrl"
Write-Host ""

# Build signtool command
$args = @(
    "sign",
    "/f", $PfxPath,
    "/tr", $TimestampUrl,
    "/td", "sha256",
    "/fd", "sha256"
)

if ($PfxPassword) {
    $args += "/p", $PfxPassword
}

$args += $InstallerPath

# Execute signing
Write-Host "Signing..." -ForegroundColor Yellow
& $signtool @args

if ($LASTEXITCODE -ne 0) {
    Write-Error "Code signing failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Verify signature
Write-Host ""
Write-Host "Verifying signature..." -ForegroundColor Yellow
& $signtool verify /pa /v $InstallerPath

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Signature verification returned warnings"
} else {
    Write-Host ""
    Write-Host "✅ Code signing successful!" -ForegroundColor Green
    Write-Host "   $InstallerPath"
    Write-Host ""
}

exit $LASTEXITCODE
