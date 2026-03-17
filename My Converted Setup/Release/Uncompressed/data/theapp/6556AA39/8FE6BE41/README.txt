============================================================
  NeaPay Complete - Enterprise Installer Package v1.0.0
============================================================

  Product:     NeaPay Complete Payment Platform
  Version:     1.0.0
  Date:        March 2026
  Author:      Eric Miller
  
  This package contains everything needed to build a
  professional Windows installer for NeaPay Complete.

============================================================
  QUICK START
============================================================

1. EXTRACT THIS ZIP to your build machine
   Recommended: C:\Builds\NeaPay-Complete-Installer\

2. INSTALL PREREQUISITES:
   - InstallAware X14 (or later)
   - Windows SDK (for code signing)
   - PowerShell 5.1+ or PowerShell 7+

3. BUILD THE INSTALLER:
   Option A - PowerShell (recommended):
   ```
   cd C:\Builds\NeaPay-Complete-Installer
   .\build.ps1
   ```

   Option B - InstallAware Studio GUI:
   - Open "installer\NeaPayComplete.mpr" in InstallAware Studio
   - Click Build → Build Project

4. SIGN THE INSTALLER (optional but recommended):
   ```
   .\installer\sign-installer.ps1 `
     -CertPath "C:\certs\YourCodeSign.pfx" `
     -CertPassword "yourpassword"
   ```

5. OUTPUT:
   - Unsigned: dist\NeaPayComplete-1.0.0-Setup.exe
   - Signed:   dist\NeaPayComplete-1.0.0-Setup.exe (with digital signature)

============================================================
  FOLDER STRUCTURE
============================================================

├── installer/
│   ├── NeaPayComplete.mpr          # InstallAware project file
│   ├── NeaPayComplete.iam          # UAC manifest (admin elevation)
│   ├── sign-installer.ps1          # Code signing script
│   └── scripts/
│       └── InstallScript.miax       # Main installation logic
│
├── payload/
│   ├── neapay-complete/             # Application files (COPY YOURS HERE)
│   ├── config/
│   │   └── .env.example             # Environment template
│   ├── docker/
│   │   ├── docker-compose.yml       # Docker orchestration
│   │   ├── docker-compose.override.yml
│   │   └── README.txt               # Docker usage guide
│   └── third-party/
│       └── (place Docker Desktop installer here for bundling)
│
├── certs/                           # Code signing certificates (add yours)
│
├── dist/                            # Build output (auto-created)
│   └── logs/                        # Build logs
│
└── build.ps1                        # Master build script

============================================================
  CUSTOMIZATION
============================================================

1. PRODUCT INFO:
   Edit installer\NeaPayComplete.mpr
   - Change product name, version, manufacturer
   - Update GUIDs for new product identity

2. PAYLOAD:
   Copy your built NeaPay Complete files to:
   payload\neapay-complete\

3. CONFIGURATION:
   Edit payload\config\.env.example
   Set default ports, database URLs, API keys

4. DOCKER BUNDLING (optional):
   - Download Docker Desktop installer
   - Place in payload\third-party\
   - Update DOCKER_INSTALLER path in InstallScript.miax

5. CODE SIGNING:
   - Place your .pfx certificate in certs\
   - Update sign-installer.ps1 default paths if needed

============================================================
  TROUBLESHOOTING
============================================================

Issue: "InstallAware not found"
Fix:   Install InstallAware X14 or update IA_PATH in build.ps1

Issue: "Certificate not found"
Fix:   Place your .pfx in certs\ folder or specify full path

Issue: "Payload files missing"
Fix:   Copy your built neapay-complete files to payload\neapay-complete\

Issue: "Docker Desktop install fails"
Fix:   Ensure DockerDesktop.exe is in payload\third-party\
       Or disable Docker bundling in InstallScript.miax

============================================================
  REQUIREMENTS
============================================================

Minimum:
  - Windows 10/11 (64-bit)
  - 2GB free disk space
  - PowerShell 5.1+

Recommended:
  - Windows 11 Pro
  - 4GB free disk space
  - InstallAware X14 Professional
  - Valid code signing certificate

============================================================
  SUPPORT
============================================================

Documentation: https://docs.neapay.com/installer
InstallAware:  https://docs.installaware.com
NeaPay Support: support@neapay.com

============================================================
  LICENSE
============================================================

© 2026 NeaPay Systems. All rights reserved.
This installer package is provided for building the
NeaPay Complete Payment Platform installer.

============================================================
