# sandbox_wsl.ps1 - WSL sandboxing configuration

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

function Configure-WSLMounts {
    # Configure WSL mounts to mount Windows drives read-only
    $wslConfPath = "$env:USERPROFILE\.wslconfig"

    $content = @"
[wsl2]
localhostForwarding=true

[automount]
enabled=true
options=metadata,ro
mountFsTab=false
"@

    $content | Set-Content -Path $wslConfPath -Encoding ASCII

    Write-Host "WSL mounts configured to mount Windows drives read-only with metadata."
}

Configure-WSLMounts

