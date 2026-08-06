# setup.ps1 - root bootstrap script

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Starting system bootstrap..."

# Import modules
. "$PSScriptRoot\constants.ps1"
. "$PSScriptRoot\browser.ps1"
. "$PSScriptRoot\wsl_sandbox.ps1"
. "$PSScriptRoot\user_management.ps1"
. "$PSScriptRoot\monitoring.ps1"
. "$PSScriptRoot\rclone.ps1"
. "$PSScriptRoot\logs.ps1"
. "$PSScriptRoot\sandbox_browser.ps1"
. "$PSScriptRoot\registry_hardening.ps1"

# Stepwise execution
Invoke-BrowserSandbox
Configure-WSLMounts
Create-LocalUser -Username $DefaultUsername -Password $DefaultPassword
Enable-AutoLogin -Username $DefaultUsername -Password $DefaultPassword
Install-Sysmon

# Optional rclone install based on user prompt
if ($args -contains "rclone") {
    Install-Rclone
}

Write-Host "Applying registry hardening..."
. "$PSScriptRoot\registry_hardening.ps1"

Write-Host "Bootstrap complete. Rebooting to finalize..."
Restart-Computer -Force

