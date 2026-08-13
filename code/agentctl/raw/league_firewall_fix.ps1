$GameExe = "C:\Riot Games\League of Legends\Game\League of Legends.exe"

if (Test-Path $GameExe) {
    New-NetFirewallRule -DisplayName "League Game Process UDP Out" `
    -Direction Outbound `
    -Program $GameExe `
    -Protocol UDP `
    -RemotePort 5000-5500,8088 `
    -Action Allow -ErrorAction SilentlyContinue

    New-NetFirewallRule -DisplayName "League Game Process TCP Out" `
    -Direction Outbound `
    -Program $GameExe `
    -Protocol TCP `
    -RemotePort 443 `
    -Action Allow -ErrorAction SilentlyContinue
}