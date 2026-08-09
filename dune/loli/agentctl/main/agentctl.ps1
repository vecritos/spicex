# ==========================================
# Agentctl Main CLI / State Machine Module
# ==========================================

# Ensure Administrator
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:AgentctlRoot = Join-Path ${env:ProgramFiles} "Agentctl"
if (-not (Test-Path $Script:AgentctlRoot)) {
    New-Item -ItemType Directory -Path $Script:AgentctlRoot -Force | Out-Null
}

# ------------------------------------------------
# Import submodules
# ------------------------------------------------
$Modules = @(
    "bootstrap.ps1",
    "logs.ps1",
    "network.ps1",
    "registry.ps1",
    "wsl.ps1"
)
foreach ($mod in $Modules) {
    $path = Join-Path $Script:AgentctlRoot $mod
    if (Test-Path $path) {
        . $path
    } else {
        Write-Warning "Module $mod not found at $path"
    }
}

# ------------------------------------------------
# CLI Dispatch
# ------------------------------------------------
function Show-Help {
    Write-Host "Agentctl CLI Help" -ForegroundColor Cyan
    Write-Host "Usage: agentctl {verb} [args]"
    Write-Host ""
    Write-Host "Verbs:"
    Write-Host "  bootstrap {object}    : Bootstrap system (hardening, WSL, network, logs, registry)"
    Write-Host "  bootstrap-status      : Show bootstrap state"
    Write-Host "  bootstrap-reset       : Reset bootstrap (forced re-fetch)"
    Write-Host "  network-harden        : Harden network settings"
    Write-Host "  network-disable       : Disable all adapters"
    Write-Host "  network-enable        : Enable all adapters"
    Write-Host "  logs-open [logname]   : Open log file"
    Write-Host "  logs-inspect [logname] [--shred max|quick] : Inspect & shred logs"
    Write-Host "  wsl-setup             : Install/configure WSL with swap/proxy"
    Write-Host "  registry-harden       : Apply registry hardening"
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

        # -------------------------------
        # Bootstrap
        # -------------------------------
        "bootstrap" { 
            if (-not $Args) { Write-Warning "Specify object to bootstrap"; return }
            Write-Host "Bootstrapping object: $($Args[0])" -ForegroundColor Cyan
            Invoke-Bootstrap @Args
        }
        "bootstrap-status" { 
            $bs = Get-Content (Join-Path $Script:AgentctlRoot "bootstrap.json") -Raw | ConvertFrom-Json
            Write-Host "Bootstrap status:"; $bs | Format-List
        }
        "bootstrap-reset" {
            Write-Host "Resetting bootstrap..."
            # Re-fetch files if needed, then call bootstrap
            Enable-NetworkAdapters
            . (Join-Path $Script:AgentctlRoot "sachi.ps1")
            Invoke-Bootstrap
            Disable-NetworkAdapters
            Write-Host "Bootstrap reset complete."
        }

        # -------------------------------
        # Network
        # -------------------------------
        "network-harden" { Invoke-NetworkHarden }
        "network-disable" { Disable-NetworkAdapters }
        "network-enable" { Enable-NetworkAdapters }

        # -------------------------------
        # Logs
        # -------------------------------
        "logs-open" { Open-Logs @Args }
        "logs-inspect" { Inspect-Logs @Args }

        # -------------------------------
        # WSL
        # -------------------------------
        "wsl-setup" { Invoke-WSLSetup @Args }

        # -------------------------------
        # Registry
        # -------------------------------
        "registry-harden" { Invoke-RegistryHarden }

        # -------------------------------
        # Help
        # -------------------------------
        "help" { Show-Help }

        Default { Write-Warning "Unknown verb '$Verb'. Run 'agentctl help' for usage." }
    }
}

# ------------------------------------------------
# Export CLI
# ------------------------------------------------
Export-ModuleMember -Function Invoke-Agentctl,Show-Help

