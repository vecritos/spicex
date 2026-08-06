# monitoring.ps1 - Sysmon and other monitoring setup

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

function Install-Sysmon {
    # Download and install Sysmon, configure basic event logging
    Write-Host "Installing Sysmon..."

    $sysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
    $zipPath = "$env:TEMP\sysmon.zip"
    $installDir = "$env:ProgramFiles\Sysmon"

    Invoke-WebRequest -Uri $sysmonUrl -OutFile $zipPath -UseBasicParsing

    Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force
    Start-Process -FilePath (Join-Path $env:TEMP "Sysmon64.exe") -ArgumentList "-accepteula -i" -Wait

    Remove-Item $zipPath -Force
    Write-Host "Sysmon installed."
}

Install-Sysmon

