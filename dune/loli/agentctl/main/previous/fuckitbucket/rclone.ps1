# rclone.ps1 - rclone installation and config management

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

function Install-Rclone {
    if (Get-Command rclone -ErrorAction SilentlyContinue) {
        Write-Host "Rclone already installed."
        return
    }
    $url = "https://downloads.rclone.org/rclone-current-windows-amd64.zip"
    $zipPath = "$env:TEMP\rclone.zip"
    $installDir = "$env:ProgramFiles\rclone"

    Write-Host "Downloading rclone..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force

    Move-Item -Path (Join-Path $env:TEMP "rclone-*-windows-amd64\rclone.exe") -Destination $installDir -Force

    # Add to PATH if needed
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if (-not ($currentPath -like "*$installDir*")) {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$installDir", "Machine")
        Write-Host "Added rclone to system PATH. Please restart shell to refresh PATH."
    }

    Remove-Item $zipPath -Force
    Remove-Item (Join-Path $env:TEMP "rclone-*-windows-amd64") -Recurse -Force
    Write-Host "Rclone installation complete."
}

function Configure-Rclone-Google {
    param (
        [string]$ConfigFile = "$env:USERPROFILE\.config\rclone\rclone.conf"
    )
    Write-Host "Please run the following to configure Google Drive manually:"
    Write-Host "`trclone config"
    Write-Host "Make sure to save the config at $ConfigFile"
}

function Open-RcloneFirewallPort {
    Write-Host "Opening firewall ports for rclone sync..."
    # Open port 22 for SSH or any other used by rclone
    New-NetFirewallRule -DisplayName "Rclone SSH Port 22" -Direction Outbound -Protocol TCP -LocalPort Any -RemotePort 22 -Action Allow -Profile Any
}

function Close-RcloneFirewallPort {
    Write-Host "Closing firewall ports for rclone sync..."
    Get-NetFirewallRule -DisplayName "Rclone SSH Port 22" | Remove-NetFirewallRule -Confirm:$false
}

# CLI dispatch
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install","config-google","open","close")]
    [string]$Action
)

switch ($Action) {
    "install" { Install-Rclone }
    "config-google" { Configure-Rclone-Google }
    "open" { Open-RcloneFirewallPort }
    "close" { Close-RcloneFirewallPort }
    default { Write-Error "Unknown rclone action." }
}

