# ==========================================
# Agentctl CLI Dispatch Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

# Module Root
$Script:AgentctlRoot = Join-Path ${env:ProgramFiles} "Agentctl"
if (-not (Test-Path $Script:AgentctlRoot)) {
    New-Item -ItemType Directory -Path $Script:AgentctlRoot -Force | Out-Null
}

# Import submodules
$Modules = @("wsl.ps1","network.ps1","logs.ps1")
foreach ($mod in $Modules) {
    $path = Join-Path $Script:AgentctlRoot $mod
    if (Test-Path $path) {
        . $path
    } else {
        Write-Warning "Module $mod not found at $path"
    }
}

function Show-Help {
    Write-Host "Agentctl CLI Help" -ForegroundColor Cyan
    Write-Host "Usage: agentctl {verb} [args]"
    Write-Host ""
    Write-Host "Verbs:"
    Write-Host "  wsl-setup             : Install and configure WSL with swap/proxy"
    Write-Host "  network-harden        : Harden firewall and network settings"
    Write-Host "  network-disable       : Disable all network adapters"
    Write-Host "  network-enable        : Enable all network adapters"
    Write-Host "  logs-open [logname]   : Open a log file (default agentctl.log)"
    Write-Host "  logs-inspect [logname] [--shred max|quick] : Inspect and securely shred logs"
    Write-Host "  bootstrap-status      : Show current bootstrap state"
    Write-Host "  bootstrap-reset       : Reset bootstrap (force network reconnection and reinit)"
    Write-Host "  help                  : Show this message"
}

function Invoke-Agentctl {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Verb,
        [Parameter(Position=1)]
        [string[]]$Args
    )

    switch ($Verb.ToLower()) {
        "help" { Show-Help }

        # WSL
        "wsl-setup" { Invoke-WSLSetup @Args }

        # Network
        "network-harden" { Invoke-NetworkHarden }
        "network-disable" { Disable-NetworkAdapters }
        "network-enable" { Enable-NetworkAdapters }

        # Logs
        "logs-open" { Open-Logs @Args }
        "logs-inspect" { Inspect-Logs @Args }

        # Bootstrap
        "bootstrap-status" {
            $bs = Get-Content (Join-Path $Script:AgentctlRoot "bootstrap.json") -Raw | ConvertFrom-Json
            Write-Host "Bootstrap status:"
            $bs | Format-List
        }
        "bootstrap-reset" {
            Write-Host "Resetting bootstrap..."
            # Re-fetch files from repo (placeholder)
            Write-Host "Pulling latest agentctl files from repository..."
            # Re-enable network if needed
            Enable-NetworkAdapters
            # Call bootstrapping
            . (Join-Path $Script:AgentctlRoot "bootstrap.ps1")
            Disable-NetworkAdapters
            Write-Host "Bootstrap reset complete."
        }

        Default { Write-Warning "Unknown verb '$Verb'. Run 'agentctl help' for usage." }
    }
}

# If called directly from CLI
if ($MyInvocation.InvocationName -eq ".") {
    Show-Help
}

Export-ModuleMember -Function Invoke-Agentctl,Show-Help

