# wsl_sandbox.ps1

function Configure-WSLMounts {
    Write-Host "Configuring WSL mounts with restricted permissions..."

    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    $configContent = @"
[wsl2]
localhostForwarding=true

[automount]
enabled=true
root = /mnt/
options = "metadata,umask=0077,fmask=0177"
mountFsTab=true
"@

    if (-not (Test-Path $wslConfigPath)) {
        Write-Host "Creating $wslConfigPath..."
        $configContent | Out-File -FilePath $wslConfigPath -Encoding ASCII
    }
    else {
        Write-Host "$wslConfigPath already exists. Backing up and appending necessary options..."
        Copy-Item $wslConfigPath "$wslConfigPath.bak"
        $existingContent = Get-Content $wslConfigPath
        if ($existingContent -notcontains $configContent) {
            Add-Content $wslConfigPath $configContent
        }
    }
    Write-Host "WSL mount configuration complete."
}

