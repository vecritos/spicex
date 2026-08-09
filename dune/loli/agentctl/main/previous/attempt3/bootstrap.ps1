# bootstrap.ps1 - Complete system bootstrap script

# Import or dot-source other scripts (adjust relative paths as needed)
. .\RegistryHardening.ps1
. .\NetworkHardening.ps1
. .\AgentctlSetup.ps1

function Remove-OEMPackages {
    Write-Host "Removing OEM packages..."
    $oemPackages = Get-AppxPackage | Where-Object { $_.Publisher -like "*OEM*" }
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
    param(
        [string]$Username,
        [SecureString]$Password
    )

    Write-Host "Creating local user '$Username'..."
    try {
        New-LocalUser -Name $Username -Password $Password -FullName $Username -Description "Local user created by bootstrap" -PasswordNeverExpires -AccountNeverExpires
        Add-LocalGroupMember -Group "Administrators" -Member $Username
        Write-Host "User '$Username' created and added to Administrators."
    } catch {
        Write-Warning "Failed to create user: $_"
    }
}

function Enable-AutoLogin {
    param(
        [string]$Username,
        [string]$PlainPassword
    )

    Write-Host "Enabling auto-login for user '$Username'..."
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

    Set-ItemProperty -Path $registryPath -Name "DefaultUsername" -Value $Username
    Set-ItemProperty -Path $registryPath -Name "DefaultPassword" -Value $PlainPassword
    Set-ItemProperty -Path $registryPath -Name "AutoAdminLogon" -Value "1"

    Write-Host "Auto-login enabled."
}

function Start-Bootstrap {
    Write-Host "Starting system bootstrap..."

    # Prompt for username and password
    $username = Read-Host "Enter local username to create"
    $password = Read-Host "Enter password for user '$username'" -AsSecureString
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

    Remove-OEMPackages
    Create-LocalUser -Username $username -Password $password
    Enable-AutoLogin -Username $username -PlainPassword $plainPassword

    # Clear plain password from memory
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

    # Call next setup phases
    Write-Host "Running registry hardening..."
    Invoke-RegistryHardening

    Write-Host "Running network hardening..."
    Invoke-NetworkHardening

    Write-Host "Setting up agentctl..."
    Invoke-AgentctlSetup

    # Final reboot
    Write-Host "Bootstrap complete. Rebooting now..."
    Restart-Computer -Force
}

# Run bootstrap if script is run directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-Bootstrap
}

