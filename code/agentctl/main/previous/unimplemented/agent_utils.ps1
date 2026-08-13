# agent_utils.ps1
# Utility functions for agentctl

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    $logEntry = "$timestamp [$Level] $Message"
    Write-Output $logEntry
}
