# agentctl.ps1
# Main CLI wrapper calling the agent core and submodules

param (
    [Parameter(Mandatory=$true)][string]$Command,
    [string]$Payload,
    [switch]$Force
)

Import-Module "$PSScriptRoot\agent_constants.ps1"
Import-Module "$PSScriptRoot\agent_utils.ps1"
Import-Module "$PSScriptRoot\agent_auth.ps1"
Import-Module "$PSScriptRoot\agent_acl.ps1"
Import-Module "$PSScriptRoot\agent_ipc.ps1"
Import-Module "$PSScriptRoot\agent_firewall.ps1"
Import-Module "$PSScriptRoot\agent_dns.ps1"
Import-Module "$PSScriptRoot\agent_monitoring.ps1"
Import-Module "$PSScriptRoot\agent_logging.ps1"
Import-Module "$PSScriptRoot\agent_backup.ps1"
Import-Module "$PSScriptRoot\agent_browser.ps1"
Import-Module "$PSScriptRoot\agent_wsl.ps1"

switch ($Command.ToLower()) {
    "startpipe" {
        Start-AgentPipeServer
    }
    "setupfirewall" {
        Apply-DefaultDenyFirewall
    }
    "setupdns" {
        Set-DNSConfiguration
    }
    "setuprclone" {
        Install-Rclone
        Setup-RcloneConfig
        Add-RcloneFilterForSecrets
    }
    "setupbrowser" {
        Setup-BrowserSandbox
    }
    "setupwsl" {
        Setup-WSLSandbox
    }
    "ping" {
        Write-Output "pong"
    }
    default {
        Write-Warning "Unknown command $Command"
    }
}
