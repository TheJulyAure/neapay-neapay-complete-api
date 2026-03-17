# 🖥️ InstallAware X14 Project - Complete

Full production-grade installer project for NeaPay Complete.

## 📁 Folder Structure

```
installaware/
├── installer/
│   ├── NeaPayComplete.mpr          # InstallAware project
│   ├── NeaPayComplete.iam          # Code signing manifest
│   ├── sign-installer.ps1          # Code signing script
│   └── scripts/
│       └── InstallScript.miax      # Installation script
│
├── payload/
│   ├── neapay-complete/            # Built app (from build.ps1)
│   ├── config/
│   │   └── .env.example
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   └── docker-compose.override.yml
│   └── third-party/
│       └── docker-desktop-installer.exe
│
├── dist/
│   ├── NeaPayComplete-1.0.0-Setup.exe
│   └── logs/
│
├── certs/                          # Code signing certificates
├── build.ps1                       # Build script
└── INSTALLAWARE_README.md
```

## 🚀 Quick Start

### 1. Build the Installer

```powershell
cd installaware
.\build.ps1 -Version "1.0.0"
```

### 2. Code Sign (Optional)

```powershell
.\installer\sign-installer.ps1 -InstallerPath "dist\NeaPayComplete-1.0.0-Setup.exe" -PfxPath "certs\NeaPayCodeSign.pfx" -PfxPassword "xxx"
```

### 3. Manual Build (InstallAware GUI)

1. Open `installer\NeaPayComplete.mpr` in InstallAware X14
2. Build to `dist\`

## 📦 What the Installer Does

| Phase | Actions |
|-------|---------|
| **Pre-install** | Windows 10+ check, 500MB disk, Docker detection |
| **Install Docker** | Bundled silent install if missing |
| **Copy Files** | App + Docker configs + scripts |
| **Create Shortcuts** | Start Menu + Desktop |
| **Post-install** | Open browser with app |

## 🔧 Requirements

- Windows 10/11
- InstallAware X14 (for GUI builds)
- Docker Desktop (bundled or pre-installed)
- Code signing certificate (for release)

## 📋 Files

| File | Purpose |
|------|---------|
| `NeaPayComplete.mpr` | Main InstallAware project |
| `NeaPayComplete.iam` | Admin manifest, UAC, compatibility |
| `InstallScript.miax` | Full installation logic |
| `build.ps1` | Automated payload + build |
| `sign-installer.ps1` | signtool wrapper |

## 🔐 Code Signing

1. Get a code signing certificate (.pfx)
2. Place in `certs/`
3. Run signing script

```powershell
.\installer\sign-installer.ps1 -InstallerPath "dist\NeaPayComplete-1.0.0-Setup.exe" -PfxPath "certs\NeaPayCodeSign.pfx" -PfxPassword "your-password"
```

## 📖 Documentation

- InstallAware Docs: https://docs.installaware.com
- NeaPay Support: https://neapay.com/support
