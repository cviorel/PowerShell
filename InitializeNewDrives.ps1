# Initialize and format new disks

# http://stackoverflow.com/questions/34320503/powershell-script-to-initialize-new-drives-naming-them-from-array
# http://www.vsysad.com/2016/08/format-ntfs-disk-with-allocation-unit-size-of-64k-via-powershell/

#$Disk = Get-Disk -Number 1
#Set-Disk -InputObject $Disk -IsOffline $false
#Initialize-Disk -InputObject $Disk
#New-Partition $Disk.Number -UseMaximumSize -DriveLetter E
#Format-Volume -DriveLetter E -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel DATAFILES -Confirm:$false


### Stops the Hardware Detection Service ###
Stop-Service -Name ShellHWDetection

### Grabs all the new RAW disks into a variable ###
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $null -ne $_.Number }

### Starts a foreach loop that will add the drive
### and format the drive for each RAW drive
### the OS detects ###
foreach ($d in $disk) {
    $diskNumber = $d.Number
    $dl = Get-Disk $d.Number | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize
    Format-Volume -DriveLetter $dl.Driveletter -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel "New Disk $diskNumber" -Confirm:$false
    ### 2 Second pause between each disk ###
    ### Initialization, Partitioning, and formatting ###
    Start-Sleep 2
}
### Starts the Hardware Detection Service again ###
Start-Service -Name ShellHWDetection

### end of script ###
