# agentctl.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    [string[]]$Args
)

switch ($Command.ToLower()) {
    "bootstrap" { . .\setup.ps1 @Args }
    "rclone" {
        if ($Args[0] -eq "open") {
            Open-RcloneFirewallPort
        } elseif ($Args[0] -eq "close") {
            Close-RcloneFirewallPort
        } elseif ($Args[0] -eq "install") {
            Install-Rclone
        } elseif ($Args[0] -eq "config") {
            # Placeholder for rclone config commands
            Write-Host "Run 'agentctl rclone config google' to configure Google Drive."
        }
        else {
            Write-Host "Unknown rclone command."
        }
    }
    "logs" {
        if ($Args[0] -eq "open") {
            Start-LogScraping
        } elseif ($Args[0] -eq "inspect") {
            $mode = if ($Args.Count -gt 1) { $Args[1] } else { "max" }
            Inspect-Logs -Mode $mode
        } else {
            Write-Host "Unknown logs command."
        }
    }
    "user" { . .\user_management.ps1 @Args }
    "monitor" { . .\monitoring.ps1 @Args }
    "sandbox-browser" { . .\sandbox_browser.ps1 @Args }
    "sandbox-wsl" { . .\wsl_sandbox.ps1 @Args }
    "registry-hardening" { . .\registry_hardening.ps1 @Args }
    "firewall" {
        if ($Args[0] -eq "configure") {
            Configure-Firewall
        } elseif ($Args[0] -eq "rclone" -and $Args[1] -eq "open") {
            Open-RcloneFirewallPort
        } elseif ($Args[0] -eq "rclone" -and $Args[1] -eq "close") {
            Close-RcloneFirewallPort
        }
        else {
            Write-Host "Unknown firewall command."
        }
    }
    default {
        Write-Error "Unknown command: $Command"
        Write-Host "Available commands: bootstrap, rclone, logs, user, monitor, sandbox-browser, sandbox-wsl, registry-hardening, firewall"
    }
}

