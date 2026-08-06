# firewall.ps1

function Configure-Firewall {
    Write-Host "Configuring firewall rules..."

    # Default policies
    Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultInboundAction Block -DefaultOutboundAction Allow

    # Allow loopback and local subnet
    New-NetFirewallRule -DisplayName "Allow Loopback" -Direction Inbound -LocalAddress 127.0.0.1 -Action Allow -Profile Any
    New-NetFirewallRule -DisplayName "Allow Local Subnet" -Direction Inbound -RemoteAddress LocalSubnet -Action Allow -Profile Any

    # Block SMB1 and legacy protocols (example)
    New-NetFirewallRule -DisplayName "Block SMB1" -Direction Inbound -Protocol TCP -LocalPort 139,445 -Action Block -Profile Any

    Write-Host "Firewall configured."
}

function Open-RcloneFirewallPort {
    Write-Host "Opening port 22 for rclone SSH syncing..."
    New-NetFirewallRule -DisplayName "Allow Rclone SSH" -Direction Outbound -Protocol TCP -RemotePort 22 -Action Allow -Profile Any -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Allow Rclone SSH Inbound" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any -ErrorAction SilentlyContinue
}

function Close-RcloneFirewallPort {
    Write-Host "Closing port 22 for rclone SSH syncing..."
    Get-NetFirewallRule -DisplayName "Allow Rclone SSH" | Remove-NetFirewallRule -ErrorAction SilentlyContinue
}

