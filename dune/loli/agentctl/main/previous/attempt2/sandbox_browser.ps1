# sandbox_browser.ps1

function Invoke-BrowserSandbox {
    Write-Host "Launching Edge browser sandbox..."

    $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edgePath)) {
        Write-Error "Microsoft Edge not found."
        return
    }

    # Launch Edge in InPrivate mode with minimal permissions
    Start-Process $edgePath -ArgumentList "--inprivate --no-first-run --no-default-browser-check"

    Write-Host "Browser sandbox launched."
}

