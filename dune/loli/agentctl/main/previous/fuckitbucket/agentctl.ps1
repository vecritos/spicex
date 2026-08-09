# agentctl.ps1 - main CLI for agentctl commands

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

param(
    [string]$Command,
    [string[]]$Args
)

switch ($Command.ToLower()) {
    "bootstrap" {
        if ($Args -contains "status") {
            $status = Get-ItemPropertyValue -Path $AGENTCTL_REG_ROOT -Name $BOOTSTRAP_LATCH_NAME -ErrorAction SilentlyContinue
            if ($status -eq 1) {
                Write-Host "Bootstrap completed."
            } else {
                Write-Host "Bootstrap not completed or unknown."
            }
        }
        elseif ($Args -contains "reset") {
            $force = $Args -contains "--force"
            & "$PSScriptRoot\bootstrap.ps1" @("--Force=$force")
        }
        else {
            Write-Host "Unknown bootstrap command."
        }
    }
    "logs" {
        # Placeholder for logs commands
        Write-Host "Logs functionality coming soon."
    }
    "rclone" {
        # Placeholder for rclone setup commands
        Write-Host "Rclone functionality coming soon."
    }
    default {
        Write-Host "Unknown command: $Command"
    }
}

