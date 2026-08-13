# ==========================================
# Agentctl Logging & Secure Log Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:AgentctlRoot = Join-Path ${env:ProgramFiles} "Agentctl"
$Script:LogsRoot = Join-Path $Script:AgentctlRoot "logs"
$Script:LogsStateFile = Join-Path $Script:AgentctlRoot "logs.json"

function Initialize-LogsModule {
    if (-not (Test-Path $Script:LogsRoot)) {
        New-Item -ItemType Directory -Path $Script:LogsRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:LogsStateFile)) {
        $state = @{ lastOpen = $null; lastInspect = $null; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:LogsStateFile -Encoding UTF8
    }
}

function Get-LogsState {
    Initialize-LogsModule
    Get-Content $Script:LogsStateFile -Raw | ConvertFrom-Json
}

function Set-LogsState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:LogsStateFile -Encoding UTF8
}

function Open-Logs {
    param(
        [string]$LogName = "agentctl.log"
    )
    Initialize-LogsModule
    $logPath = Join-Path $Script:LogsRoot $LogName
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType File | Out-Null
    }

    Write-Host "Opening logs at $logPath" -ForegroundColor Cyan
    # Example: simulate scraping logs
    Add-Content -Path $logPath -Value "Log opened at $(Get-Date -Format u)"
    $state = Get-LogsState
    $state.lastOpen = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-LogsState -State $state
}

function Inspect-Logs {
    param(
        [string]$LogName = "agentctl.log",
        [ValidateSet("max","quick")] [string]$ShredMode = "max"
    )
    Initialize-LogsModule
    $logPath = Join-Path $Script:LogsRoot $LogName
    if (-not (Test-Path $logPath)) {
        Write-Warning "$logPath does not exist."
        return
    }

    # Disable network during inspection
    Write-Host "Disabling network adapters for inspection..." -ForegroundColor Yellow
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | Disable-NetAdapter -Confirm:$false

    Write-Host "Entering interactive log inspection for $logPath..."
    Get-Content $logPath | ForEach-Object {
        Write-Host $_
        $null = Read-Host "Press Enter to continue to next line"
    }

    # Shred or zero logs depending on mode
    switch ($ShredMode) {
        "max" {
            Write-Host "Shredding logs with random data..."
            $length = (Get-Item $logPath).Length
            $bytes = New-Object byte[] $length
            (New-Object System.Random).NextBytes($bytes)
            [System.IO.File]::WriteAllBytes($logPath, $bytes)
        }
        "quick" {
            Write-Host "Zeroing out log file quickly..."
            Clear-Content -Path $logPath
        }
    }

    # Update state
    $state = Get-LogsState
    $state.lastInspect = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-LogsState -State $state

    # Re-enable network if needed
    # potential vulnerability to leave more than one adapter up?
    Write-Host "Re-enabling network adapters..." -ForegroundColor Green
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Disabled"} | Enable-NetAdapter -Confirm:$false
}

Export-ModuleMember -Function Initialize-LogsModule,Get-LogsState,Set-LogsState,Open-Logs,Inspect-Logs

