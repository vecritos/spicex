# agent_firewall.ps1
# Firewall rules management

function Apply-DefaultDenyFirewall {
    Write-Host "Applying default deny firewall rules..."
    netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound | Out-Null

    # Allow DNS
    netsh advfirewall firewall add rule name="Allow DNS" protocol=udp dir=out remoteport=53 action=allow | Out-Null
    # Allow HTTP
    netsh advfirewall firewall add rule name="Allow HTTP" protocol=tcp dir=out remoteport=80 action=allow | Out-Null
    # Allow HTTPS
    netsh advfirewall firewall add rule name="Allow HTTPS" protocol=tcp dir=out remoteport=443 action=allow | Out-Null
    Write-Host "Firewall rules applied."
}
