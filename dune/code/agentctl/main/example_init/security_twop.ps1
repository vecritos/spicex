# ================================================
# MASTER STATE-LEVEL HARDENING + WSL2 SECURE PIPELINE
# Author: Your Security Architect
# ================================================

Write-Host "=== Starting Master State-Level Hardening & WSL2 Setup ===" -ForegroundColor Cyan

# ------------------------------
# 1️⃣ HOST HARDENING – Windows Core
# ------------------------------

Write-Host "Applying Windows Hardening..." -ForegroundColor Yellow

# Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Legacy protocols
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LmCompatibilityLevel" -Value 5 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -Name "UseLogonCredential" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "RunAsPPL" -Value 1 -PropertyType DWord -Force

# Exploit mitigations
Set-ProcessMitigation -System -Enable DEP,SEHOP,CFG,ASLR

# Disable remote services
Set-Service -Name RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name RemoteRegistry -Force -ErrorAction SilentlyContinue
Set-Service -Name FDResPub -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name FDResPub -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 1

# Block outbound PowerShell
if (-not (Get-NetFirewallRule -DisplayName "Block PowerShell Outbound" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Block PowerShell Outbound" `
        -Direction Outbound `
        -Program "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -Action Block -Profile Any
}

# Memory Integrity (HVCI)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force | Out-Null
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" `
    -Name "EnableVirtualizationBasedSecurity" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" `
    -Name "Enabled" -Value 1 -PropertyType DWord -Force

# Defender ASR Rules
$ASRRules = @{
    "9e6c4e1f-7a1a-4e16-8f64-ff5c7a8e36c3" = "Enabled"
    "d4f940ab-401b-4efc-aadc-ad5f3c50688a" = "Enabled"
    "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" = "Enabled"
}
foreach ($rule in $ASRRules.Keys) {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule `
                     -AttackSurfaceReductionRules_Actions Enabled `
                     -ErrorAction SilentlyContinue
}

# BitLocker C:
$BLV = Get-BitLockerVolume -MountPoint "C:"
if ($BLV.VolumeStatus -ne "FullyEncrypted") {
    Enable-BitLocker -MountPoint "C:" `
        -EncryptionMethod XtsAes256 `
        -UsedSpaceOnly `
        -TpmProtector
}

# Max UAC
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "ConsentPromptBehaviorAdmin" -Value 2 -PropertyType DWord -Force

Write-Host "Host hardening applied. Reboot required for full effect." -ForegroundColor Green

# ------------------------------
# 2️⃣ WSL2 Installation & Ubuntu Setup
# ------------------------------

Write-Host "Setting up WSL2 (Ubuntu 24.04)..." -ForegroundColor Yellow

# Enable WSL2 feature
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart

# Install Ubuntu 24.04
wsl --install -d Ubuntu-24.04

# Set WSL2 as default
wsl --set-default-version 2

# Create folders inside WSL2 for encrypted archives
wsl -d Ubuntu-24.04 -- bash -c "mkdir -p ~/SecureArchives"

# Install CLI tools for encryption inside WSL2
wsl -d Ubuntu-24.04 -- bash -c "sudo apt update && sudo apt install -y p7zip-full gnupg rsync"

Write-Host "WSL2 setup complete. Secure archive folder created." -ForegroundColor Green

# ------------------------------
# 3️⃣ Encrypting Files for Upload in WSL2
# ------------------------------

Write-Host "Example: Encrypt files inside WSL2 before cloud upload..." -ForegroundColor Yellow

# Command to encrypt using 7z AES256 inside WSL2
Write-Host "Use this inside WSL2:"
Write-Host @"
cd ~/SecureArchives
7z a -t7z MyData_$(date +%Y%m%d_%H%M).7z /mnt/c/Users/YourUser/SensitiveData -pYourStrongPassphrase -mhe=on
"@

Write-Host "This creates a timestamped encrypted archive for upload." -ForegroundColor Green

# ------------------------------
# 4️⃣ Metadata Hygiene & Timing Control
# ------------------------------

Write-Host "Reminder: Strip metadata and batch uploads." -ForegroundColor Yellow
Write-Host @"
# Inside WSL2 example:

# Remove EXIF from images
sudo apt install -y exiftool
exiftool -all= ~/SecureArchives/MyData_*.jpg

# Randomize upload timing (batch uploads)
sleep \$((RANDOM % 1800))  # sleep 0–30 min before upload
"@

# ------------------------------
# 5️⃣ Optional Networking Discipline
# ------------------------------

Write-Host "Optional: Use VPN / Tor inside WSL2 for cloud uploads to decouple IP/timestamp correlation."
Write-Host @"
# Example:
sudo apt install -y tor torsocks
torsocks rclone copy ~/SecureArchives/MyData_20260211_*.7z cryptremote:securefolder
"@

Write-Host "=== Master Hardening + WSL2 Secure Pipeline Ready ===" -ForegroundColor Green
Write-Host "Remember: Only decrypt inside WSL2 or isolated environment. Do not mix with host OS." -ForegroundColor Cyan

