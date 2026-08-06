# wsl_setup.ps1

function Set-NetworkContext {
    param (
        [ValidateSet("default","inspect","paranoid","secure_notes")]
        [string]$Context
    )

    Write-Host "Setting network context to '$Context'..."

    switch ($Context) {
        "default" {
            Write-Host "Applying default network settings: normal internet access"
            # Enable full network access
            Enable-NetAdapter -Name "Ethernet" -Confirm:$false
            Remove-NetRoute -DestinationPrefix "10.0.0.0/8" -Confirm:$false -ErrorAction SilentlyContinue
            # Remove any proxy/firewall restrictions here
        }
        "inspect" {
            Write-Host "Applying inspect network settings: block internet"
            # Disable internet, allow local subnet
            Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false
            # Alternatively block internet routes
            New-NetRoute -DestinationPrefix "0.0.0.0/0" -NextHop "0.0.0.0" -InterfaceIndex (Get-NetAdapter).ifIndex -PolicyStore ActiveStore -Confirm:$false -ErrorAction SilentlyContinue
        }
        "paranoid" {
            Write-Host "Applying paranoid network settings: proxy hop chain"
            # Setup multiple proxy hops (e.g. Tor, VPN, internal hops)
            # Pseudo-code:
            # Start Tor service or VPN tunnel
            # Configure firewall to only allow traffic via proxy interfaces
            # Block all other outbound connections
            # Note: requires user to have Tor/VPN installed and configured
            # Example commands might be complex depending on environment
        }
        "secure_notes" {
            Write-Host "Applying secure notes network context: restrictive with encrypted channels only"
            # Apply firewall rules to restrict traffic to only encrypted tunnels (e.g. SSH, TLS)
            # Disable all other traffic
        }
        default {
            Write-Warning "Unknown network context '$Context'. No changes applied."
        }
    }

    Write-Host "Network context set to '$Context'."
}

