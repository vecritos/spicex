# ==========================================
# Sandbox Module
# ==========================================

# Paths and Constants
$Script:AgentctlRoot = Join-Path ${env:ProgramFiles} "Agentctl"
$Script:SandboxRoot = Join-Path $Script:AgentctlRoot "sandbox"
$Script:SandboxConfig = Join-Path $Script:SandboxRoot "sandbox.json"

function Initialize-Sandbox {
    if (-not (Test-Path $Script:SandboxRoot)) {
        New-Item -ItemType Directory -Path $Script:SandboxRoot -Force | Out-Null
    }

    if (-not (Test-Path $Script:SandboxConfig)) {
        $config = @{
            active = $false
            lastRun = ""
            blockedSites = @()
            wslInstance = "agentctl-sandbox"
        }
        $config | ConvertTo-Json | Set-Content -Path $Script:SandboxConfig -Encoding UTF8
    }
}

function Get-SandboxConfig {
    Initialize-Sandbox
    Get-Content $Script:SandboxConfig -Raw | ConvertFrom-Json
}

function Set-SandboxConfig {
    param([Parameter(Mandatory)][object]$Config)
    $Config | ConvertTo-Json | Set-Content -Path $Script:SandboxConfig -Encoding UTF8
}

# -------------------------------
# Start Sandbox
# -------------------------------
function Invoke-SandboxStart {
    $config = Get-SandboxConfig
    if ($config.active) {
        Write-Warning "Sandbox already active."
        return
    }

    Write-Host "Starting sandbox environment..." -ForegroundColor Cyan

    # Example: Launch isolated WSL instance
    # WSL instance assumed created in wsl.ps1
    wsl.exe -d $config.wslInstance -- cd ~
    
    # Mark active
    $config.active = $true
    $config.lastRun = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-SandboxConfig -Config $config

    Write-Host "Sandbox active. All processes should run isolated here." -ForegroundColor Green
}

# -------------------------------
# Stop Sandbox
# -------------------------------
function Invoke-SandboxStop {
    $config = Get-SandboxConfig
    if (-not $config.active) {
        Write-Warning "Sandbox not active."
        return
    }

    Write-Host "Stopping sandbox environment..." -ForegroundColor Cyan

    # Example: Terminate WSL instance processes
    wsl.exe -t $config.wslInstance

    # Mark inactive
    $config.active = $false
    Set-SandboxConfig -Config $config

    Write-Host "Sandbox stopped." -ForegroundColor Green
}

# -------------------------------
# Inspect Sandbox
# -------------------------------
function Invoke-SandboxInspect {
    $config = Get-SandboxConfig
    Write-Host "Sandbox configuration:" -ForegroundColor Cyan
    $config | Format-List
}

# -------------------------------
# Export Functions
# -------------------------------
Export-ModuleMember -Function Initialize-Sandbox,Get-SandboxConfig,Set-SandboxConfig,Invoke-SandboxStart,Invoke-SandboxStop,Invoke-SandboxInspect

