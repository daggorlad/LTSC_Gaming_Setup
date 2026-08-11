# Windows 11 LTSC Master Setup: Tweaks, Gaming Meta, & Hardening
# Run as Administrator

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   Windows 11 LTSC Master Setup Initialization       " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$gpuChoice = Read-Host "Select GPU optimization path (1 = NVIDIA, 2 = AMD, 3 = Skip)"
Write-Host ""

# ==============================================================================
# SECTION 1: BASIC SYSTEM TWEAKS
# ==============================================================================
Write-Host ">>> SECTION 1: Applying Basic System Tweaks..." -ForegroundColor Green

# Disable Windows Search Indexing Service to prevent disk I/O spikes
Write-Host "-> Disabling Windows Search Service..." -ForegroundColor Yellow
Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
Set-Service -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue

# Disable USB Selective Suspend (Fixes mouse polling dropouts)
Write-Host "-> Disabling USB Selective Suspend..." -ForegroundColor Yellow
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea129aa0a 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea129aa0a 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /S SCHEME_CURRENT


# ==============================================================================
# SECTION 2: GAMING META (PERFORMANCE & SOFTWARE)
# ==============================================================================
Write-Host "`n>>> SECTION 2: Applying Gaming Meta & Software..." -ForegroundColor Green

# Disable VBS and Memory Integrity (HVCI)
Write-Host "-> Disabling VBS and Memory Integrity (HVCI)..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Type DWord -Force

# Disable Virtual Machine Platform (VMP)
Write-Host "-> Disabling Virtual Machine Platform..." -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue

# Enable Hardware-Accelerated GPU Scheduling (HAGS)
Write-Host "-> Enabling HAGS..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force

# Optimize Windows Timers (Disable HPET & Dynamic Tick)
Write-Host "-> Optimizing System Timers..." -ForegroundColor Yellow
bcdedit /set useplatformclock false | Out-Null
bcdedit /set useplatformtick yes | Out-Null
bcdedit /set disabledynamictick yes | Out-Null

# Install Gaming Software Stack
Write-Host "-> Installing Gaming Software Stack..." -ForegroundColor Yellow
$gamingApps = @("EpicGames.EpicGamesLauncher", "Microsoft.XboxApp", "Microsoft.GamingServicesRepairTool")

if ($gpuChoice -eq "1") {
    $gamingApps += "TechPowerUp.NVCleanstall"
    Write-Host "-> NVIDIA selected: NVCleanstall added to gaming software queue." -ForegroundColor DarkGray
}

foreach ($app in $gamingApps) {
    winget install --id $app --exact --accept-package-agreements --accept-source-agreements --silent
}


# ==============================================================================
# SECTION 3: SYSTEM HARDENING (PRIVACY & SECURITY)
# ==============================================================================
Write-Host "`n>>> SECTION 3: Applying System Hardening..." -ForegroundColor Green

# GPU Telemetry Hardening
if ($gpuChoice -eq "2") {
    Write-Host "-> AMD selected: Hard-disabling AMD User Experience telemetry via registry..." -ForegroundColor Yellow
    New-Item -Path "HKLM:\SOFTWARE\AMD\WVR" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\AMD\WVR" -Name "EnableTelemetry" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\AMD\WVR" -Name "EnableExperienceProgram" -Value 0 -Type DWord -Force
}

# Install Privacy & Hardening Software Stack
Write-Host "-> Installing Privacy Browsers & Default-Deny Firewall..." -ForegroundColor Yellow
$hardeningApps = @("Waterfox.Waterfox", "Brave.Brave", "OOSoftware.ShutUp10", "Henry++.Simplewall")

foreach ($app in $hardeningApps) {
    winget install --id $app --exact --accept-package-agreements --accept-source-agreements --silent
}

# DNS over HTTPS (DoH) - Quad9
Write-Host "-> Configuring Quad9 DNS over HTTPS (DoH)..." -ForegroundColor Yellow
Add-DnsClientDohServerAddress -ServerAddress "9.9.9.9" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $False -ErrorAction SilentlyContinue
Add-DnsClientDohServerAddress -ServerAddress "149.112.112.112" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $False -ErrorAction SilentlyContinue

$adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
if ($adapter) {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("9.9.9.9","149.112.112.112")
}

# Execute O&O ShutUp10++ Recommended Policies Silently
Write-Host "-> Applying O&O ShutUp10++ Privacy Policies..." -ForegroundColor Yellow
$OOUtility = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\OOSoftware.ShutUp10_Microsoft.Winget.Source_8wekyb3d8bbwe\OOSU10.exe"

if (Test-Path $OOUtility) {
    Start-Process -FilePath $OOUtility -ArgumentList "/quiet /nosrp" -Wait
    Write-Host "-> O&O Privacy rules successfully applied." -ForegroundColor DarkGray
} else {
    Write-Host "-> Notice: Could not automate O&O ShutUp10. Please run manually." -ForegroundColor Red
}


# ==============================================================================
# SECTION 4: POST-INSTALLATION REMINDERS & CHRIS TITUS WINUTIL
# ==============================================================================
Write-Host "`n=====================================================" -ForegroundColor Magenta
Write-Host "      ACTION REQUIRED: MANUAL POST-INSTALL STEPS     " -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta
Write-Host "1. MSI Mode Utility v3:" -ForegroundColor White
Write-Host "   - Download from Guru3D forums." -ForegroundColor Gray
Write-Host "   - Run as Admin -> Check 'MSI' for GPU & NVMe -> Set Priority to 'High' -> Apply." -ForegroundColor Gray
Write-Host ""
Write-Host "2. Simplewall Firewall:" -ForegroundColor White
Write-Host "   - Open Simplewall from your Start Menu." -ForegroundColor Gray
Write-Host "   - Click 'Enable filtering' to activate the default-deny egress firewall." -ForegroundColor Gray
Write-Host ""
Write-Host "3. GPU Driver Installation:" -ForegroundColor White
if ($gpuChoice -eq "1") {
    Write-Host "   - Open NVCleanstall to install your NVIDIA drivers without telemetry." -ForegroundColor Gray
} elseif ($gpuChoice -eq "2") {
    Write-Host "   - Install AMD Adrenalin using the 'Driver Only' or 'Minimal Install' option." -ForegroundColor Gray
}
Write-Host ""
Write-Host "4. Chris Titus Tech Utility (Opening Now):" -ForegroundColor White
Write-Host "   - Navigate to the 'Tweaks' tab." -ForegroundColor Gray
Write-Host "   - Click 'Standard' tweaks." -ForegroundColor Gray
Write-Host "   - REBOOT your PC after completing these steps." -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Magenta

Start-Sleep -Seconds 5

# Launch CTT WinUtil at the very end
iex "& { $(irm christitus.com/win) }"
