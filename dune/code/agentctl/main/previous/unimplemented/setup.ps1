# setup.ps1
# Bootstrap installation and config orchestration

Write-Host "Starting agentctl setup..."

# Create directories
if (-not (Test-Path $CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
}
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

# Run core setups
# .gentctl.ps1 setupfirewall
.agentctl.ps1 setupfirewall
.agentctl.ps1 setupdns
.agentctl.ps1 setuprclone
.agentctl.ps1 setupbrowser
.agentctl.ps1 setupwsl

Write-Host "Setup complete. Starting agent pipe server in background..."
Start-Job { .agentctl.ps1 startpipe } | Out-Null

Write-Host "agentctl is running. Use agentctl.ps1 with commands to interact."
