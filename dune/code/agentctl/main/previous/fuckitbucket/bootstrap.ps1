# bootstrap.ps1 - bootstrap agentctl from GitHub repo

# Constants
$AGENTCTL_REPO_BASE = "https://raw.githubusercontent.com/username/agentctl/main"
$LOCAL_AGENT_DIR = "$env:USERPROFILE\agentctl"

function Enable-Network {
    Get-NetAdapter | Where-Object {$_.Status -ne 'Up'} | Enable-NetAdapter -Confirm:$false
}

function Disable-Network {
    Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Disable-NetAdapter -Confirm:$false
}

# Ensure directory exists
if (-not (Test-Path $LOCAL_AGENT_DIR)) {
    New-Item -Path $LOCAL_AGENT_DIR -ItemType Directory | Out-Null
}

Write-Host "Bootstrapping agentctl to $LOCAL_AGENT_DIR..." -ForegroundColor Cyan

$files = @(
    "constants.ps1",
    "agentctl.ps1",
    "hardening.ps1",
    "firewall.ps1",
    "bootstrap.ps1"
)

Enable-Network

foreach ($file in $files) {
    $url = "$AGENTCTL_REPO_BASE/$file"
    $destination = Join-Path $LOCAL_AGENT_DIR $file

    try {
        Write-Host "Downloading $file..."
        Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to download $file: $_"
        exit 1
    }
}

Disable-Network

Write-Host "Bootstrap complete. To run agentctl, use:" -ForegroundColor Green
Write-Host "`t& '$LOCAL_AGENT_DIR\agentctl.ps1' <command> [args]"

# Optionally run initial hardening
# & "$LOCAL_AGENT_DIR\hardening.ps1"

