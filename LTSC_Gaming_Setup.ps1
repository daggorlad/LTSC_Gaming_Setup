# Windows 11 LTSC Master Setup: Tweaks, Gaming Meta, & Hardening
# Run as Administrator
# Includes GPU detection, optimized stack, silent installs, and integrated CTT Standard tweaks

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   Windows 11 LTSC Master Setup Initialization       " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Create a restore point first
Write-Host "-> Creating System Restore Point (Pre-Setup)..." -ForegroundColor Yellow
Checkpoint-Computer -Description "Pre-LTSC-Master-Setup" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue

# ==============================================================================
# GPU DETECTION
# ==============================================================================
Write-Host "-> Detecting GPU..." -ForegroundColor Yellow

$gpuControllers = Get-CimInstance -ClassName Win32_VideoController |
    Where-Object {
        $_.Name -notmatch "Microsoft Basic|Remote Desktop|Virtual|Parallels|VMware|QXL" -and
        $_.AdapterRAM -gt 0
    } |
    Sort-Object -Property AdapterRAM -Descending

$detectedGPU = "Unknown"
$gpuName = "None"

if ($gpuControllers) {
    $primary = $gpuControllers | Select-Object -First 1
    $gpuName = $primary.Name

    if ($gpuName -match "NVIDIA|GeForce|RTX|GTX|Quadro|Tesla") {
        $detectedGPU = "NVIDIA"
    }
    elseif ($gpuName -match "AMD|Radeon|RX |FirePro|Instinct") {
        $detectedGPU = "AMD"
    }
}

Write-Host "   Detected: $gpuName" -ForegroundColor DarkGray
Write-Host "   Type    : $detectedGPU" -ForegroundColor DarkGray
Write-Host ""

# Smart prompt with detected default
switch ($detectedGPU) {
    "NVIDIA" { $defaultChoice = "1" }
    "AMD"    { $defaultChoice = "2" }
    default  { $defaultChoice = "3" }
}

$prompt = "Select GPU optimization path (1 = NVIDIA, 2 = AMD, 3 = Skip)"
if ($detectedGPU -ne "Unknown") {
    $prompt += " [Detected: $detectedGPU — press Enter for $defaultChoice]"
}

$gpuChoice = Read-Host $prompt
if ([string]::IsNullOrWhiteSpace($gpuChoice)) {
    $gpuChoice = $defaultChoice
}

$gpuChoice = $gpuChoice.Trim()
if ($gpuChoice -notin @("1", "2", "3")) {
    Write-Host "Invalid choice. Defaulting to Skip." -ForegroundColor Red
    $gpuChoice = "3"
}

$choiceLabel = switch ($gpuChoice) {
    "1" { "NVIDIA" }
    "2" { "AMD" }
    default { "Skip" }
}
Write-Host "-> Using GPU path: $choiceLabel" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# SECTION 1: BASIC SYSTEM TWEAKS
# ==============================================================================
Write-Host ">>> SECTION 1: Applying Basic System Tweaks..." -ForegroundColor Green

# Disable Windows Search Indexing Service
Write-Host "-> Disabling Windows Search Service..." -ForegroundColor Yellow
Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
Set-Service -Name WSearch -StartupType Disabled -ErrorAction SilentlyContinue

# Disable USB Selective Suspend
Write-Host "-> Disabling USB Selective Suspend..." -ForegroundColor Yellow
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea129aa0a 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bea129aa0a 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /S SCHEME_CURRENT

# Disable Fast Startup / Hibernation
Write-Host "-> Disabling Fast Startup and Hibernation..." -ForegroundColor Yellow
powercfg /hibernate off
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Enable Ultimate Performance power plan
Write-Host "-> Enabling Ultimate Performance power plan..." -ForegroundColor Yellow
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
$ultimate = powercfg -list | Select-String "Ultimate Performance"
if ($ultimate) {
    $guid = ($ultimate.ToString() -split '\s+')[3]
    powercfg -setactive $guid
    Write-Host "   Ultimate Performance plan activated." -ForegroundColor DarkGray
}

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

# Optimize Windows Timers
Write-Host "-> Optimizing System Timers..." -ForegroundColor Yellow
bcdedit /set useplatformclock false | Out-Null
bcdedit /set useplatformtick yes | Out-Null
bcdedit /set disabledynamictick yes | Out-Null

# Network latency optimizations
Write-Host "-> Applying network latency optimizations..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

# Raise Games task priority under MMCSS
Write-Host "-> Raising Games scheduling priority..." -ForegroundColor Yellow
$gamesPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
New-Item -Path $gamesPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $gamesPath -Name "GPU Priority" -Value 8 -Type DWord -Force
Set-ItemProperty -Path $gamesPath -Name "Priority" -Value 6 -Type DWord -Force
Set-ItemProperty -Path $gamesPath -Name "Scheduling Category" -Value "High" -Type String -Force
Set-ItemProperty -Path $gamesPath -Name "SFIO Priority" -Value "High" -Type String -Force

# Enable Game Mode
Write-Host "-> Enabling Game Mode..." -ForegroundColor Yellow
New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force

# -------------------------------------------------
# Core Gaming Software Stack
# -------------------------------------------------
Write-Host "-> Installing Core Gaming Software Stack..." -ForegroundColor Yellow

$gamingApps = @(
    "Valve.Steam",
    "EpicGames.EpicGamesLauncher",
    "Microsoft.XboxApp",
    "Microsoft.GamingServicesRepairTool",
    "Discord.Discord",
    "Guru3D.Afterburner",
    "REALiX.HWiNFO",
    "7zip.7zip",
    "Notepad++.Notepad++"
)

if ($gpuChoice -eq "1") {
    $gamingApps += "TechPowerUp.NVCleanstall"
    Write-Host "-> NVIDIA selected: NVCleanstall added." -ForegroundColor DarkGray
}

foreach ($app in $gamingApps) {
    Write-Host "   Installing $app..." -ForegroundColor DarkGray
    winget install --id $app --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade
}

# -------------------------------------------------
# Optional Launchers
# -------------------------------------------------
Write-Host ""
Write-Host "Optional Launchers:" -ForegroundColor Cyan
Write-Host "  1 = Battle.net (Blizzard)" -ForegroundColor Gray
Write-Host "  2 = GOG Galaxy" -ForegroundColor Gray
Write-Host "  3 = Ubisoft Connect" -ForegroundColor Gray
Write-Host "  4 = All three" -ForegroundColor Gray
Write-Host "  5 = Skip" -ForegroundColor Gray
Write-Host ""

$launcherChoice = Read-Host "Select optional launchers (1-5)"

$optionalLaunchers = @()

switch ($launcherChoice) {
    "1" { $optionalLaunchers = @("Blizzard.BattleNet") }
    "2" { $optionalLaunchers = @("GOG.Galaxy") }
    "3" { $optionalLaunchers = @("Ubisoft.Connect") }
    "4" { $optionalLaunchers = @("Blizzard.BattleNet", "GOG.Galaxy", "Ubisoft.Connect") }
    default {
        Write-Host "-> Skipping optional launchers." -ForegroundColor DarkGray
    }
}

if ($optionalLaunchers.Count -gt 0) {
    Write-Host "-> Installing selected optional launchers..." -ForegroundColor Yellow
    foreach ($app in $optionalLaunchers) {
        Write-Host "   Installing $app..." -ForegroundColor DarkGray
        winget install --id $app --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade
    }
}

# ==============================================================================
# SECTION 3: SYSTEM HARDENING + CTT STANDARD TWEAKS
# ==============================================================================
Write-Host "`n>>> SECTION 3: Applying System Hardening..." -ForegroundColor Green

# GPU-specific telemetry hardening
if ($gpuChoice -eq "2") {
    Write-Host "-> AMD selected: Hard-disabling AMD User Experience telemetry..." -ForegroundColor Yellow
    New-Item -Path "HKLM:\SOFTWARE\AMD\WVR" -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\AMD\WVR" -Name "EnableTelemetry" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\AMD\WVR" -Name "EnableExperienceProgram" -Value 0 -Type DWord -Force
}

# Core telemetry services
Write-Host "-> Disabling core telemetry services..." -ForegroundColor Yellow
$telemetryServices = @("DiagTrack", "dmwappushservice", "WerSvc")
foreach ($svc in $telemetryServices) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# Telemetry policy + privacy registry
Write-Host "-> Applying telemetry policy and privacy registry keys..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord -Force

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Disable LLMNR
Write-Host "-> Disabling LLMNR..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Type DWord -Force

# Disable SMBv1
Write-Host "-> Disabling SMBv1..." -ForegroundColor Yellow
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue

# Install Privacy & Hardening Software Stack
Write-Host "-> Installing Privacy Browsers & Default-Deny Firewall..." -ForegroundColor Yellow
$hardeningApps = @(
    "Waterfox.Waterfox",
    "Brave.Brave",
    "OOSoftware.ShutUp10",
    "Henry++.Simplewall"
)

foreach ($app in $hardeningApps) {
    Write-Host "   Installing $app..." -ForegroundColor DarkGray
    winget install --id $app --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade
}

# DNS over HTTPS (DoH) - Quad9
Write-Host "-> Configuring Quad9 DNS over HTTPS (DoH)..." -ForegroundColor Yellow
Add-DnsClientDohServerAddress -ServerAddress "9.9.9.9" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $False -ErrorAction SilentlyContinue
Add-DnsClientDohServerAddress -ServerAddress "149.112.112.112" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $False -ErrorAction SilentlyContinue

$adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
if ($adapter) {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("9.9.9.9", "149.112.112.112")
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
# Running Chris Titus Tech Standard Tweaks (Integrated)
# Credit: Chris Titus Tech - https://christitus.com / https://github.com/ChrisTitusTech/winutil
# ==============================================================================
Write-Host "`n>>> Running Chris Titus Tech Standard Tweaks..." -ForegroundColor Magenta
Write-Host "    (Integrated from CTT WinUtil Standard preset)" -ForegroundColor DarkGray

# Activity History / Timeline
Write-Host "-> Disabling Activity History..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0 -Type DWord -Force

# Consumer Features
Write-Host "-> Disabling Windows Consumer Features..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force

# Location Tracking
Write-Host "-> Disabling Location Tracking..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# WPBT
Write-Host "-> Disabling WPBT..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWpbtExecution" -Value 1 -Type DWord -Force

# Delivery Optimization
Write-Host "-> Disabling Delivery Optimization..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -Type DWord -Force

# Services optimization + SvcHostSplitThreshold
Write-Host "-> Optimizing background services (CTT style)..." -ForegroundColor Yellow
$servicesToManual = @("MapsBroker", "StorSvc")
$servicesToDisable = @("DiagTrack", "dmwappushservice", "SharedAccess", "CscService")

foreach ($svc in $servicesToManual) {
    Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
}
foreach ($svc in $servicesToDisable) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

$memoryKB = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Value $memoryKB -Type DWord -Force

# Explorer AutoDiscovery cleanup
Write-Host "-> Cleaning Explorer AutoDiscovery (BagMRU)..." -ForegroundColor Yellow
Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" -Recurse -Force -ErrorAction SilentlyContinue

# End Task on Taskbar
Write-Host "-> Enabling End Task on Taskbar..." -ForegroundColor Yellow
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord -Force

# Delete Temporary Files
Write-Host "-> Cleaning temporary files..." -ForegroundColor Yellow
Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "-> Chris Titus Tech Standard Tweaks completed." -ForegroundColor Magenta

# ==============================================================================
# SECTION 4: POST-INSTALLATION REMINDERS
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
} else {
    Write-Host "   - Install your GPU drivers manually." -ForegroundColor Gray
}
Write-Host ""
Write-Host "4. Tools installed:" -ForegroundColor White
Write-Host "   - Steam, Discord, MSI Afterburner, HWiNFO, 7-Zip, Notepad++" -ForegroundColor Gray
Write-Host "   - Privacy stack: Waterfox, Brave, O&O ShutUp10, Simplewall" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Post-reboot checks:" -ForegroundColor White
Write-Host "   - Confirm Ultimate Performance is active in Power Options." -ForegroundColor Gray
Write-Host "   - Verify VBS / Memory Integrity is still off in Windows Security." -ForegroundColor Gray
Write-Host "=====================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Setup complete. Please reboot your PC." -ForegroundColor Green
Write-Host ""
