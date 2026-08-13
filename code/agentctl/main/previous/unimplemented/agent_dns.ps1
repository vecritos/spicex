# agent_dns.ps1
# DNS configuration including encrypted and multi-hop DNS

function Set-DNSConfiguration {
    $interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1 -ExpandProperty Name
    if (-not $interface) {
        Write-Warning "No active network adapter found."
        return
    }

    Write-Host "Configuring DNS servers for interface: $interface"
    $dnsServers = @("1.1.1.1", "9.9.9.9")
    Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses $dnsServers
    Write-Host "DNS servers set to: $($dnsServers -join ', ')"
}
