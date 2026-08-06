function Resize-WindowsForDualBoot {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [ValidateRange(1,99)]
        [int]$WindowsPercent,

        [Parameter(Mandatory)]
        [ValidateRange(1,99)]
        [int]$SwapPercent,

        [Parameter(Mandatory)]
        [ValidateRange(1,99)]
        [int]$LinuxPercent,

        [switch]$Force
    )

    if (($WindowsPercent + $SwapPercent + $LinuxPercent) -ne 100) {
        throw "Percentages must add up to 100."
    }

    Write-Host "Dual-boot resize (percent-of-disk model)"
    Write-Host "Windows: $WindowsPercent% | Swap: $SwapPercent% | Linux: $LinuxPercent%"

    # System disk
    $disk = Get-Disk | Where-Object IsSystem -eq $true
    if (-not $disk) {
        throw "System disk not found."
    }

    $diskSize = $disk.Size

    # Windows partition
    $winPart = Get-Partition -DiskNumber $disk.Number |
        Where-Object { $_.DriveLetter } |
        Sort-Object Size -Descending |
        Select-Object -First 1

    if (-not $winPart) {
        throw "Windows partition not found."
    }

    # Target sizes
    $targetWinBytes  = [math]::Floor($diskSize * ($WindowsPercent / 100))
    $swapBytes       = [math]::Floor($diskSize * ($SwapPercent / 100))
    $linuxBytes      = $diskSize - $targetWinBytes - $swapBytes

    if ($winPart.Size -le $targetWinBytes) {
        throw "Windows partition is already smaller than or equal to target size."
    }

    $supported = Get-PartitionSupportedSize `
        -DiskNumber $disk.Number `
        -PartitionNumber $winPart.PartitionNumber

    if ($targetWinBytes -lt $supported.SizeMin) {
        throw "Target Windows size is below NTFS safe minimum."
    }

    Write-Host ""
    Write-Host "Planned layout:"
    Write-Host " Windows: $([math]::Round($targetWinBytes/1GB,2)) GB"
    Write-Host " Swap:    $([math]::Round($swapBytes/1GB,2)) GB"
    Write-Host " Linux:   $([math]::Round($linuxBytes/1GB,2)) GB"
    Write-Host ""

    if (-not $Force) {
        $confirm = Read-Host "Type YES to apply disk changes"
        if ($confirm -ne "YES") {
            Write-Host "Aborted."
            return
        }
    }

    if ($PSCmdlet.ShouldProcess("Disk $($disk.Number)", "Resize Windows and create Linux partitions")) {

        # Shrink Windows
        Resize-Partition `
            -DiskNumber $disk.Number `
            -PartitionNumber $winPart.PartitionNumber `
            -Size $targetWinBytes

        # Swap partition (Linux swap type)
        $swap = New-Partition `
            -DiskNumber $disk.Number `
            -Size $swapBytes

        Set-Partition `
            -DiskNumber $disk.Number `
            -PartitionNumber $swap.PartitionNumber `
            -GptType "{0657FD6D-A4AB-43C4-84E5-0933C84B4F4F}"

        # Linux encrypted partition (LUKS)
        $linux = New-Partition `
            -DiskNumber $disk.Number `
            -Size $linuxBytes

        Set-Partition `
            -DiskNumber $disk.Number `
            -PartitionNumber $linux.PartitionNumber `
            -GptType "{CA7D7CCB-63ED-4C53-861C-1742536059CC}"
    }

    Write-Host "Done. Format swap and encrypt Linux from your Linux installer."
}

