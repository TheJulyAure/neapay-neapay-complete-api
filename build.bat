@echo off
REM ===========================================
REM InstallAware Build Script for NeaPay Complete
REM ===========================================

echo ============================================
echo NeaPay Complete - InstallAware Build Script
echo ============================================
echo.

REM Check for InstallAware installation
set IA_DIR="C:\Program Files\InstallAware 2024"
if not exist %IA_DIR% (
    set IA_DIR="C:\Program Files (x86)\InstallAware 2024"
)

if not exist %IA_DIR% (
    echo ERROR: InstallAware is not installed.
    echo Please install InstallAware Studio from https://www.installaware.com
    exit /b 1
)

echo InstallAware found at: %IA_DIR%
echo.

REM Set build configuration
set CONFIG=%1
if "%CONFIG%"=="" set CONFIG=Release

echo Building configuration: %CONFIG%
echo.

REM Create output directory
if not exist "%~dp0Installers" mkdir "%~dp0Installers"

REM Build the installer
echo Building NeaPay Complete installer...
"%IA_DIR%\IABuild.exe" "%~dp0NeaPayComplete.iap" -c %CONFIG% -o "%~dp0Installers"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo Build completed successfully!
    echo Output: %~dp0Installers
    echo ============================================
) else (
    echo.
    echo ERROR: Build failed with error code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

echo.
pause
