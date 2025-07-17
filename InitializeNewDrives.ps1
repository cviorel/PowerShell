<#
.SYNOPSIS
Initializes and formats new RAW disks.

.DESCRIPTION
The Initialize-NewDrives function stops the Hardware Detection Service, identifies all new RAW disks, initializes them, creates new partitions, formats the partitions, and then restarts the Hardware Detection Service. It processes each new RAW disk individually and provides status updates.

.PARAMETER None
This function does not take any parameters.

.EXAMPLE
PS C:\> Initialize-NewDrives
This command initializes and formats all new RAW disks found on the system.

.NOTES
- The function stops the ShellHWDetection service before processing the disks and restarts it after processing.
- The function uses a 2-second pause between processing each disk.
- The function formats the new partitions with NTFS file system and sets the allocation unit size to 65536.
- The function labels each new disk as "New Disk <disk number>".

#>
function Initialize-NewDrives {
    # Initialize and format new disks

    # Stops the Hardware Detection Service
    Stop-Service -Name ShellHWDetection

    # Grabs all the new RAW disks into a variable
    $newDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $null -ne $_.Number }

    # Check if there are any new disks to process
    if ($newDisks.Count -eq 0) {
        Write-Host "No new RAW disks found."
    } else {
        # Process each new RAW disk
        foreach ($disk in $newDisks) {
            try {
                $diskNumber = $disk.Number
                Write-Host "Processing disk number $diskNumber..."

                # Initialize the disk and create a new partition
                $partition = Initialize-Disk -Number $diskNumber -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize

                # Format the new partition
                Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel "New Disk $diskNumber" -Confirm:$false

                Write-Host "Disk number $diskNumber has been initialized, partitioned, and formatted."

                # 2 Second pause between each disk
                Start-Sleep 2
            } catch {
                Write-Error "An error occurred while processing disk number $diskNumber: $_"
            }
        }
    }

    # Starts the Hardware Detection Service again
    Start-Service -Name ShellHWDetection

    Write-Host "Script execution completed."
}
