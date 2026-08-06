function Agentctl-Download(
    [Parameter(Mandatory=$true)]
    [string]$Url
)

if (-Not (Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

Write-Host "Downloading Setup script from $Url ..."
Invoke-WebRequest -Uri $Url -OutFile $scriptPath


