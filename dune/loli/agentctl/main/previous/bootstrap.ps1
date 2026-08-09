# bootstrap.ps1 - Complete system bootstrap script

# Import or dot-source other scripts (adjust relative paths as needed)
. .\RegistryHardening.ps1
. .\NetworkHardening.ps1
. .\AgentctlSetup.ps1

function Remove-OEMPackages {
    Write-Host "Removing OEM packages..."
    $oemName = Read-Host "Manufacturer Name e.g. DELL"
    $oemPackages = Get-AppxPackage | Where-Object { $_.Publisher -like "*$oemName*" }
    foreach ($pkg in $oemPackages) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
            Write-Host "Removed $($pkg.Name)"
        } catch {
            Write-Warning "Failed to remove $($pkg.Name): $_"
        }
    }
}

function Create-LocalUser {
    # Prompt for username and password
    $username = Read-Host "Enter local username to create"
    $password = Read-Host "Enter password for user '$username'" -AsSecureString

    Write-Host "Creating local user '$Username'..."
    try {
        New-LocalUser -Name $username -Password $password -FullName $username -Description "Local user created by bootstrap" -passwordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $username
        Write-Host "User '$username' created and added to Administrators."

        Write-Host "Clearing powershell history"
        if (Test-Path $PROFILE.CurrentUserAllHosts) {
            Remove-Item $PROFILE.CurrentUserAllHosts -Force
        }
        if (Test-Path (Get-PSReadlineOption).HistorySavePath) {
            Remove-Item (Get-PSReadlineOption).HistorySavePath -Force
        }

        Remove-Variable password, username

        Write-Host "Type 'cls' to clear the screen (if you want to)"
    } catch {
        Write-Warning "Failed to create user: $_"
    }
}

function Start-Bootstrap {
    Write-Host "Starting system bootstrap..."

    $downloadUrl = Read-Host "What AgentCtl would you like to download? (Defaults to bootstrap repo)"

    # download agentctl
    Agentctl-Download -Url $downloadUrl

    # Remove-OEMPackages
    Create-LocalUser

    Invoke-AgentctlSetup

    # Final reboot
    Write-Host "Bootstrap complete. Rebooting now..."
    Restart-Computer -Force
}

# Run bootstrap if script is run directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-Bootstrap
}

