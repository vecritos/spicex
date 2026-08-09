# agent_wsl.ps1
# WSL sandbox and mount restrictions

function Setup-WSLSandbox {
    Write-Host "Configuring WSL sandbox mounts..."
    $wslConf = @"
[automount]
enabled = true
options = "ro,metadata"
mountFsTab = false
"@
    $wslConfPath = "$env:USERPROFILE\.wslconfig"
    $wslConf | Out-File -FilePath $wslConfPath -Encoding ascii
    Write-Host "WSL sandbox configured with read-only Windows mounts."
}
