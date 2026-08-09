# setup.ps1 - root bootstrap script

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Starting system bootstrap..."

# Import all module scripts
. "$PSScriptRoot\constants.ps1"
. "$PSScriptRoot\browser.ps1"
. "$PSScriptRoot\wsl_sandbox.ps1"
. "$PSScriptRoot\user_management.ps1"
. "$PSScriptRoot\monitoring.ps1"
. "$PSScriptRoot\rclone.ps1"
. "$PSScriptRoot\logs.ps1"
. "$PSScriptRoot\sandbox_browser.ps1"
. "$PSScriptRoot\registry_hardening.ps1"

# Execute browser sandbox setup
Write-Host "Setting up browser sandbox..."
Invoke-BrowserSandbox

# Setup WSL mounts sandbox
Write-Host "Configuring WSL sandbox..."
Configure-WSLMounts

# Setup local user and auto-login (example user)
Write-Host "Creating local user..."
Create-LocalUser -Username "agentuser" -Password "P@ssw0rd123!"
Enable-AutoLogin -Username "agentuser" -Password "P@ssw0rd123!"

# Install monitoring tools (sysmon)
Write-Host "Installing monitoring tools..."
Install-Sysmon

# Install rclone if selected
if ($args -contains "rclone") {
    Write-Host "Installing rclone sync client..."
    Install-Rclone
}

Write-Host "Applying registry hardening..."
. "$PSScriptRoot\registry_hardening.ps1"

Write-Host "Bootstrap complete. Rebooting to finalize..."
Restart-Computer -Force

