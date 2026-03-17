# 📦 NeaPay Complete - Payload Structure

This folder contains the installer payload structure.

## 📁 Folder Layout

```
payload/
├── neapay-complete/              # Application files (copied from repo)
│   ├── penthouse-api/
│   ├── frontend/
│   ├── sdk/
│   ├── docs/
│   ├── open-browser.ps1
│   ├── run-dev.ps1
│   └── ...
├── config/
│   └── .env.example              # Environment template
├── docker/
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml
│   └── README.txt
└── third-party/
    └── docker-desktop-installer.exe  # Bundled Docker Desktop
```

## 🔧 Building Payload

Run this script before building the installer:

```powershell
# From installer/ folder
.\build-payload.ps1
```

This copies files from the main repo into the payload folder.

## 📦 Third-Party Software

| Software | File | Notes |
|----------|------|-------|
| Docker Desktop | docker-desktop-installer.exe | Optional - user can skip if Docker installed |

## 🎯 Payload Size Estimate

| Component | Approx Size |
|-----------|-------------|
| Application | ~50MB |
| Docker configs | ~10KB |
| Third-party (optional) | ~500MB |
| **Total** | **~550MB** (without Docker) |
