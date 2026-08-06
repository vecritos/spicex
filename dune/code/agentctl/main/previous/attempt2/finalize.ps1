# finalize.ps1

function Finalize-Setup {
    Write-Host "Finalizing setup..."

    Configure-Firewall
    Enable-Sandboxing

    Write-Host "Setup finalized. Rebooting system..."
    Restart-Computer -Force
}

