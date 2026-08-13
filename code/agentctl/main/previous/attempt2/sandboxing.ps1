# sandboxing.ps1

function Enable-Sandboxing {
    Write-Host "Enabling Windows Sandbox feature..."

    # Enable Windows Sandbox feature if available
    $feature = Get-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -Online
    if ($feature.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart
        Write-Host "Windows Sandbox feature enabled."
    }
    else {
        Write-Host "Windows Sandbox already enabled."
    }
}

