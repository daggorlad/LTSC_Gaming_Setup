# Windows 11 LTSC Gaming Setup

A PowerShell script for a clean, high-performance, and privacy-focused Windows 11 LTSC installation.

## Why LTSC?

Windows 11 LTSC is the cleanest official starting point available from Microsoft. It ships with
significantly less bloat, fewer background processes, and no consumer apps (Copilot, Widgets,
Teams, etc.) compared to Home or Pro editions. This makes it an excellent foundation for further optimization.

## Getting Windows 11 LTSC

The official evaluation ISO can be downloaded from Microsoft:

→ [Windows 11 IoT Enterprise LTSC Evaluation]
(https://www.microsoft.com/en-us/evalcenter/download-windows-11-iot-enterprise-ltsc-eval)

**Important:**  
A genuine LTSC product key is required for full activation. Without a valid key you will see an
“Activate Windows” watermark on the desktop and face limitations with personalization (wallpaper, accent colors, themes, etc.).

## Activation Note

There are third-party Microsoft Activation Scripts/Tools available online.  

**Use them at your own risk.**  
This project does not endorse, recommend, or support the use of any unofficial activation methods. Using such tools may
violate Microsoft’s terms of service and carries potential security and legal risks.

## Quick Start

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/daggorlad/LTSC_Gaming_Setup/refs/heads/main/LTSC_Gaming_Setup.ps1 | iex
```

## What It Does

- Auto-detects NVIDIA / AMD GPU
- Applies performance & gaming tweaks (HAGS, Ultimate Performance, timers, etc.)
- Installs a curated software stack (Steam, Discord, Afterburner, HWiNFO, etc.)
- Reduces telemetry and hardens privacy
- Integrates selected **Chris Titus Tech** Standard + Advanced tweaks
- Restores classic right-click menu and removes Widgets / Copilot
- Skips already installed applications

## After Running

1. Reboot
2. Install GPU drivers (NVCleanstall for NVIDIA / Adrenalin Minimal for AMD)
3. Enable Simplewall
4. Optionally run MSI Mode Utility

## Credits

Chris Titus Tech – [WinUtil](https://github.com/ChrisTitusTech/winutil)

## Disclaimer

Use at your own risk. The script creates a restore point, but system changes are made.
This script is provided as-is. I am **not responsible** for any negative side effects, data loss, system instability, or other issues that may result from using this script. Use it at your own risk.
