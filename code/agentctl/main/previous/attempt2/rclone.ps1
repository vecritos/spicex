# rclone.ps1

function Install-Rclone {
    Write-Host "Installing rclone..."

    $zipPath = "$env:TEMP\rclone.zip"
    $extractPath = "$env:ProgramFiles\rclone"

    if (Test-Path $extractPath) {
        Write-Host "Removing existing rclone directory..."
        Remove-Item $extractPath -Recurse -Force
    }

    Invoke-WebRequest -Uri $RcloneDownloadUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $extractPath
    Remove-Item $zipPath

    # Add rclone to PATH environment variable if not already present
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
    if ($currentPath -notlike "*$extractPath*") {
        Write-Host "Adding rclone to system PATH..."
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$extractPath", [EnvironmentVariableTarget]::Machine)
    }

    Write-Host "rclone installation complete."
}

