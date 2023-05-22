#https://sid-500.com/2021/01/12/create-hyper-v-vms-with-powershell-single-multiple/
#https://tahirhassan.blogspot.com/2016/12/deleting-hyper-v-virtual-machine.html
#https://github.com/jakubpetrovic/Import-VMFromTemplate/blob/master/vm-import-script.ps1
#https://github.com/ejsiron/Posher-V/blob/main/Standalone/New-VMLinux.ps1
#https://github.com/fdcastel/Hyper-V-Automation
#https://cloudbase.it/qemu-img-windows/
#https://github.com/BenjaminArmstrong/Hyper-V-PowerShell/blob/master/Ubuntu-VM-Build/BaseUbuntuBuild.ps1

function New-LabVM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [Int64]$NewVHDSizeBytes,

        [Parameter(Mandatory = $true)]
        [int64]$MemoryStartupBytes,

        [Parameter(Mandatory = $false)]
        [switch]$Linux,

        [Parameter(Mandatory = $false)]
        [switch]$Windows,

        [Parameter(Mandatory = $false)]
        [int32]$Count
    )
}


$hyperVPaths = (Get-VMHost | Select-Object -Property VirtualMachinePath, VirtualHardDiskPath)

$vmPath = $hyperVPaths.VirtualMachinePath
$vhdPath = $hyperVPaths.VirtualHardDiskPath

$vmName = "WIN10"
$MemoryStartupBytes = 4GB
$NewVHDSizeBytes = 20GB

New-VM -Name $vmName -Path $vmPath -MemoryStartupBytes $MemoryStartupBytes -NewVHDPath "$vmName.vhdx" -NewVHDSizeBytes $NewVHDSizeBytes -Generation 2

# setup bootable disk
$BootDiskPath = 'D:\ISOs\WIN10ENT\19041.264.200511-0456.vb_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso'
$null = Add-VMDvdDrive -VMName $vmName -Path $BootDiskPath

$gen = (Get-VM -Name $vmName).Generation

if ($gen -eq 1) {
    Set-VMBios -VMName $vmName -StartupOrder CD
} else {
    Set-VMFirmware -VMName $vmName -FirstBootDevice ((Get-VMFirmware -VMName $vmName).BootOrder | Where-Object Device -Like *DvD*).Device
    Set-VMFirmware -VMName $vmName -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
}

Start-VM -Name $vmName
vmconnect $env:COMPUTERNAME $vmName

# # Linux won't boot with MicrosoftWindows Secure Boot template
# if ($Linux) {
#     Get-VM -Name $vmName | Set-VMFirmware -EnableSecureBoot On -SecureBootTemplate MicrosoftUEFICertificateAuthority
# }

# if ($Windows) {
#     Get-VM -Name $vmName | Set-VMFirmware -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
# }
