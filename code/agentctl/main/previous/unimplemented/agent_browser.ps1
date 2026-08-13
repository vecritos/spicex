# agent_browser.ps1
# Browser sandbox configuration

function Setup-BrowserSandbox {
    Write-Host "Configuring browser sandbox..."
    netsh advfirewall firewall add rule name="BrowserAllowHTTP" dir=out action=allow protocol=tcp remoteport=80 | Out-Null
    netsh advfirewall firewall add rule name="BrowserAllowHTTPS" dir=out action=allow protocol=tcp remoteport=443 | Out-Null
    Write-Host "Browser sandbox configured."
}
