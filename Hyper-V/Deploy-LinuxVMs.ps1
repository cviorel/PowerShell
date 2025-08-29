#Requires -RunAsAdministrator

#region Paths
$hyperVPaths = (Get-VMHost | Select-Object -Property VirtualMachinePath, VirtualHardDiskPath)
$vmPath = $hyperVPaths.VirtualMachinePath
#endregion Paths



$switch = Get-VMSwitch -Name 'Default Switch'








#region Kali
$vmName = "Kali"
$BootDiskPath = "d:\ISOs\Kali Linux 2021.1\kali-linux-2021.1-installer-amd64.iso"
$MemoryStartupBytes = 4GB
$NewVHDSizeBytes = 20GB

New-VM -Name $vmName -Path $vmPath -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath "$vmName.vhdx" -NewVHDSizeBytes $NewVHDSizeBytes -Generation 1

# setup bootable disk
$null = Add-VMDvdDrive -VMName $vmName -Path $BootDiskPath
$gen = (Get-VM -Name $vmName).Generation

if ($gen -eq 1) {
    Set-VMBios -VMName $vmName -StartupOrder CD
}
else {
    Set-VMFirmware -VMName $vmName -FirstBootDevice ((Get-VMFirmware -VMName $vmName).BootOrder | Where-Object Device -Like *DvD*).Device
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
}
#endregion Kali

#region BunsenLabs
$vmName = "BunsenLabs"
$BootDiskPath = "d:\ISOs\BunsenLabs Linux Lithium\lithium-1-amd64.hybrid.iso"
$MemoryStartupBytes = 4GB
$NewVHDSizeBytes = 20GB

New-VM -Name $vmName -Path $vmPath -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath "$vmName.vhdx" -NewVHDSizeBytes $NewVHDSizeBytes -Generation 1

# setup bootable disk
$null = Add-VMDvdDrive -VMName $vmName -Path $BootDiskPath
$gen = (Get-VM -Name $vmName).Generation

if ($gen -eq 1) {
    Set-VMBios -VMName $vmName -StartupOrder CD
}
else {
    Set-VMFirmware -VMName $vmName -FirstBootDevice ((Get-VMFirmware -VMName $vmName).BootOrder | Where-Object Device -Like *DvD*).Device
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
}
#endregion BunsenLabs
