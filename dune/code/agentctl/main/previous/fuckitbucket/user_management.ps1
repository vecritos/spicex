# user_management.ps1 - Local user creation and login bypass

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

function Create-LocalUser {
    param(
        [string]$Username,
        [string]$Password
    )

    if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
        Write-Host "User $Username already exists."
        return
    }

    Write-Host "Creating local user $Username..."
    $securePass = ConvertTo-SecureString $Password -AsPlainText -Force
    New-LocalUser -Name $Username -Password $securePass -FullName $Username -Description "agentctl created user"
    Add-LocalGroupMember -Group "Administrators" -Member $Username
    Write-Host "User $Username created and added to Administrators."
}

function Bypass-LoginScreen {
    Write-Host "Configuring auto-login for user..."

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $regPath -Name "AutoAdminLogon" -Value "1" -Type String
    Set-ItemProperty -Path $regPath -Name "DefaultUserName" -Value $env:USERNAME -Type String
    # Password storage is a security risk, handle accordingly

    Write-Host "Auto-login configured."
}

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create-user","bypass-login")]
    [string]$Action,
    [string]$Username,
    [string]$Password
)

switch ($Action) {
    "create-user" {
        if (-not $Username -or -not $Password) {
            Write-Error "Username and Password required for create-user."
            exit 1
        }
        Create-LocalUser -Username $Username -Password $Password
    }
    "bypass-login" {
        Bypass-LoginScreen
    }
    default {
        Write-Error "Unknown user_management action."
    }
}

