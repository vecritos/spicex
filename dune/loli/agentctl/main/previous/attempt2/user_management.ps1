# user_management.ps1

function Create-LocalUser {
    param (
        [string]$Username = "agentuser",
        [string]$Password = "P@ssw0rd123!"
    )

    if (-not ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Run as Administrator."
        exit 1
    }

    Write-Host "Creating local user $Username..."

    $securePass = ConvertTo-SecureString $Password -AsPlainText -Force

    if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
        Write-Host "User $Username already exists."
    }
    else {
        New-LocalUser -Name $Username -Password $securePass -PasswordNeverExpires -UserMayNotChangePassword
        Add-LocalGroupMember -Group "Administrators" -Member $Username
        Write-Host "User $Username created and added to Administrators."
    }
}

function Enable-AutoLogin {
    param (
        [string]$Username,
        [string]$Password
    )
    Write-Host "Enabling automatic login for $Username..."

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1" -Type String
    Set-ItemProperty -Path $regPath -Name "DefaultUserName" -Value $Username -Type String
    Set-ItemProperty -Path $regPath -Name "DefaultPassword" -Value $Password -Type String
}

