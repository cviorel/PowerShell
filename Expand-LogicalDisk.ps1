function Expand-LogicalDisk {
    param (
        [string]$driveLetter
    )

    if (!($driveLetter)) {
        $driveLetter = Read-Host 'Drive letter for the volume to be increased'
        $driveLetter = $driveLetter.ToUpper()
    }
    $availableDrives = (Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $null -ne $_.DriveLetter }).DriveLetter

    if ($availableDrives -notcontains $driveLetter) {
        Write-Host "This volume does not exist!" -ForegroundColor Red
        exit
    }

    'rescan' | diskpart | Out-Null

    # in a WFC the volume might show up multiple times, we need to make sure we get the local one
    $deviceId = (Get-CimInstance -Class Win32_Volume | Where-Object { $_.DriveLetter -match $driveLetter }).DeviceID

    $Volume = Get-Volume -DriveLetter $driveLetter | Where-Object { $_.UniqueId -eq $deviceId }
    $Sizes = $Volume | Get-Partition | Get-PartitionSupportedSize
    $SizeMax = $Sizes.sizeMax

    # Must be able to extend by at least 1Mb
    if ($Sizes.sizeMax - $Volume.Size -le 1048576) {
        Write-Host "This volume can't be extended." -ForegroundColor Red
        return
    }

    try {
        $Volume | Get-Partition | Resize-Partition -Size $SizeMax
    }
    catch {
        Write-Host "Failed to extend volume." -ForegroundColor Red
    }
}

# Expand-LogicalDisk -driveLetter D
