# Windows 11 LTSC Gaming Setup

A PowerShell script for a clean, high-performance, and privacy-focused Windows 11 LTSC installation.

## Why LTSC?

Windows 11 LTSC is the cleanest official starting point available from Microsoft. It ships with significantly less bloat, fewer background processes, and no consumer apps (Copilot, Widgets, Teams, etc.) compared to Home or Pro editions. This makes it an excellent foundation for further optimization.

## Getting Windows 11 LTSC

The official evaluation ISO can be downloaded from Microsoft:

→ [Windows 11 IoT Enterprise LTSC Evaluation](https://www.microsoft.com/en-us/evalcenter/download-windows-11-iot-enterprise-ltsc-eval)

**Important:**  
A genuine LTSC product key is required for full activation. Without a valid key you will see an “Activate Windows” watermark on the desktop and face limitations with personalization (wallpaper, accent colors, themes, etc.).

## Activation Note

There are third-party Microsoft Activation Scripts/Tools available online.  

**Use them at your own risk.**  
This project does not endorse, recommend, or support the use of any unofficial activation methods. Using such tools may violate Microsoft’s terms of service and carries potential security and legal risks.

## Quick Start

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/daggorlad/LTSC_Gaming_Setup/refs/heads/main/LTSC_Gaming_Setup.ps1 | iex
