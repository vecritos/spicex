# sandbox_browser.ps1 - Browser sandboxing and firewall setup

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$PSScriptRoot\constants.ps1"

function Setup-BrowserSandboxFirewall {
    Write-Host "Configuring browser sandbox firewall rules..."

    # Example: block browsers from direct network except via VPN or proxy
    $browsers = @("msedge.exe", "firefox.exe", "chrome.exe")
    foreach ($browser in $browsers) {
        New-NetFirewallRule -DisplayName "Block $browser direct outbound" -Direction Outbound -Program "C:\Program Files\$browser" -Action Block -Profile Any
    }
    Write-Host "Browser sandbox firewall configured."
}

Setup-BrowserSandboxFirewall

