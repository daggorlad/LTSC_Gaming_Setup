# GitHub IaC Bootstrap for Windows 11 LTSC
# Run as Administrator

$RepoBaseUrl = "https://raw.githubusercontent.com/YourUsername/YourRepo/main"
$TempDir = "C:\Temp_Setup"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

Write-Host ">>> Phase 1: Applying WinGet DSC Configuration (Software & Registry)..." -ForegroundColor Cyan
# Download the YAML configuration
Invoke-WebRequest -Uri "$RepoBaseUrl/gaming_meta.dsc.yaml" -OutFile "$TempDir\gaming_meta.dsc.yaml"
# Execute the declarative configuration
winget configure -f "$TempDir\gaming_meta.dsc.yaml" --accept-configuration-agreements

Write-Host ">>> Phase 2: Applying Permanent Privacy Group Policies via LGPO..." -ForegroundColor Cyan
# Download the LGPO utility and your zipped policy backup
Invoke-WebRequest -Uri "$RepoBaseUrl/LGPO.exe" -OutFile "$TempDir\LGPO.exe"
Invoke-WebRequest -Uri "$RepoBaseUrl/PrivacyBaseline.zip" -OutFile "$TempDir\PrivacyBaseline.zip"

# Extract the policy and apply it forcefully
Expand-Archive -Path "$TempDir\PrivacyBaseline.zip" -DestinationPath "$TempDir\PolicyBackup" -Force
& "$TempDir\LGPO.exe" /g "$TempDir\PolicyBackup"

Write-Host ">>> Phase 3: System Timers & DNS Hardening..." -ForegroundColor Cyan
# Optimize System Timers (These require bcdedit, not registry, so we keep them in the bootstrap)
bcdedit /set useplatformclock false | Out-Null
bcdedit /set useplatformtick yes | Out-Null
bcdedit /set disabledynamictick yes | Out-Null

# Force Quad9 DNS over HTTPS
Add-DnsClientDohServerAddress -ServerAddress "9.9.9.9" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $False -ErrorAction SilentlyContinue

Write-Host "Deployment Complete! Please restart your PC." -ForegroundColor Green
