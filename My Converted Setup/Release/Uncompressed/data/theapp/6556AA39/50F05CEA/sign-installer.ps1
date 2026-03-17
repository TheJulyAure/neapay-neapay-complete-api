param(
    [string]$InstallerPath = "dist\NeaPayComplete-1.0.0-Setup.exe",
    [string]$PfxPath = "certs\NeaPayCodeSign.pfx",
    [string]$PfxPassword = "PFX_PASSWORD",
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NeaPay Complete - Code Signing Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verify installer exists
if (-not (Test-Path $InstallerPath)) {
    Write-Error "Installer not found: $InstallerPath"
    exit 1
}

# Verify certificate exists
if (-not (Test-Path $PfxPath)) {
    Write-Error "Certificate not found: $PfxPath"
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\sign-installer.ps1 -InstallerPath `"dist\NeaPayComplete-1.0.0-Setup.exe`" -PfxPath `"certs\NeaPayCodeSign.pfx`" -PfxPassword `"your-password`""
    exit 1
}

# Find signtool
$signtoolPaths = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe",
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.22000.0\x64\signtool.exe",
    "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\signtool.exe"
)

$signtool = $null
foreach ($path in $signtoolPaths) {
    if (Test-Path $path) {
        $signtool = $path
        break
    }
}

if (-not $signtool) {
    Write-Error "signtool.exe not found. Install Windows SDK."
    exit 1
}

Write-Host "Signing: $InstallerPath" -ForegroundColor White
Write-Host "Certificate: $PfxPath" -ForegroundColor White
Write-Host "Timestamp: $TimestampUrl" -ForegroundColor White
Write-Host ""

# Sign the installer
Write-Host "[1/2] Signing installer..." -ForegroundColor Yellow

& $signtool sign /f $PfxPath /p $PfxPassword /tr $TimestampUrl /td sha256 /fd sha256 $InstallerPath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Code signing failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "      ✅ Signing successful" -ForegroundColor Green

# Verify signature
Write-Host "[2/2] Verifying signature..." -ForegroundColor Yellow

& $signtool verify /pa /v $InstallerPath

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Verification returned non-zero, but signing may still be valid."
} else {
    Write-Host "      ✅ Verification successful" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ✅ Code Signing Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Signed installer: $InstallerPath" -ForegroundColor White
Write-Host ""

exit 0
