# firewall.ps1 - firewall configuration and monitoring setup

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

Write-Host "Configuring firewall rules..." -ForegroundColor Cyan

# Example: block all inbound except loopback
New-NetFirewallRule -DisplayName "Block All Inbound Except Loopback" -Direction Inbound -Action Block -Enabled True -Profile Any -LocalAddress Any -RemoteAddress Any -Protocol Any -InterfaceType Any

# Example: allow outbound DNS and HTTP/HTTPS
New-NetFirewallRule -DisplayName "Allow Outbound DNS" -Direction Outbound -Action Allow -Protocol UDP -RemotePort 53
New-NetFirewallRule -DisplayName "Allow Outbound HTTP" -Direction Outbound -Action Allow -Protocol TCP -RemotePort 80
New-NetFirewallRule -DisplayName "Allow Outbound HTTPS" -Direction Outbound -Action Allow -Protocol TCP -RemotePort 443

Write-Host "Firewall configuration complete."

