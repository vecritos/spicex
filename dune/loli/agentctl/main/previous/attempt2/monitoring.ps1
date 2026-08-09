# monitoring.ps1 - Sysmon install and configuration

function Install-Sysmon {
    Write-Host "Installing Sysmon..."

    $sysmonZip = "$env:TEMP\Sysmon.zip"
    $sysmonExtract = "$env:TEMP\SysmonExtract"

    if (Test-Path $sysmonExtract) {
        Remove-Item $sysmonExtract -Recurse -Force
    }

    Invoke-WebRequest -Uri $SysmonDownloadUrl -OutFile $sysmonZip
    Expand-Archive -Path $sysmonZip -DestinationPath $sysmonExtract
    Remove-Item $sysmonZip

    $sysmonExe = Join-Path $sysmonExtract "Sysmon64.exe"

    if (Test-Path $sysmonExe) {
        # Basic install with default config and no network capture (-n)
        Start-Process -FilePath $sysmonExe -ArgumentList "-i -accepteula -n" -Wait
        Write-Host "Sysmon installed."
    }
    else {
        Write-Error "Sysmon executable not found."
    }
}

function Remove-Sysmon {
    Write-Host "Removing Sysmon service if installed..."
    $sysmonExe = "C:\Windows\Sysmon64.exe"
    if (Get-Service -Name Sysmon64 -ErrorAction SilentlyContinue) {
        Start-Process -FilePath $sysmonExe -ArgumentList "-u" -Wait
        Write-Host "Sysmon removed."
    }
    else {
        Write-Host "Sysmon not installed."
    }
}

