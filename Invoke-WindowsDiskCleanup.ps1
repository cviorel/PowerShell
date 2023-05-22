<#
	.SYNOPSIS
		This script invokes the Windows Disk Cleanup utility, enables all rules and runs it.

	.EXAMPLE
		PS> .\Invoke-WindowsDiskCleanup.ps1
    .NOTES
        https://ss64.com/nt/cleanmgr.html
        https://ss64.com/nt/cleanmgr-registry.html


        #>

Write-Output ':: Clearing CleanMgr.exe automation settings'

$getItemParams = @{
    Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
    Name        = 'StateFlags0001'
    ErrorAction = 'SilentlyContinue'
}
Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

$enabledSections = @(
    'Active Setup Temp Folders'
    'BranchCache'
    'Content Indexer Cleaner'
    'Device Driver Packages'
    'Downloaded Program Files'
    'GameNewsFiles'
    'GameStatisticsFiles'
    'GameUpdateFiles'
    'Internet Cache Files'
    'Memory Dump Files'
    'Offline Pages Files'
    'Old ChkDsk Files'
    'Previous Installations'
    'Recycle Bin'
    'Service Pack Cleanup'
    'Setup Log Files'
    'System error memory dump files'
    'System error minidump files'
    'Temporary Files'
    'Temporary Setup Files'
    'Temporary Sync Files'
    'Thumbnail Cache'
    'Update Cleanup'
    'Upgrade Discarded Files'
    'User file versions'
    'Windows Defender'
    'Windows Error Reporting Archive Files'
    'Windows Error Reporting Queue Files'
    'Windows Error Reporting System Archive Files'
    'Windows Error Reporting System Queue Files'
    'Windows ESD installation files'
    'Windows Upgrade Log Files'
)

Write-Output ':: Adding enabled disk cleanup sections...'
foreach ($keyName in $enabledSections) {
    $newItemParams = @{
        Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
        Name         = 'StateFlags0001'
        Value        = 2
        PropertyType = 'DWord'
        ErrorAction  = 'SilentlyContinue'
    }
    $null = New-ItemProperty @newItemParams
}

Write-Output ':: Starting CleanMgr.exe...'
Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait

Write-Output ':: Waiting for CleanMgr and DismHost processes...'
Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process

Write-Output ":: Clear recent items"
$directories = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"
)

$directories | ForEach-Object {
    if (Test-Path "$_") {
        Get-ChildItem -Path "$_\*" -File -Force | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# Cleaning up unused devices REF:https://www.uwe-sieber.de/misc_tools_e.html
if (Test-Path -Path 'D:\Tools\DeviceCleanupCmd\x64\DeviceCleanupCmd.exe') {
    Write-Output ":: Cleaning up all unused devices from the system."
    Start-Process -FilePath 'D:\Tools\DeviceCleanupCmd\x64\DeviceCleanupCmd.exe' -ArgumentList '-s -n *'
    Get-Process -Name DeviceCleanupCmd -ErrorAction SilentlyContinue | Wait-Process
    Write-Output ":: Device cleanup complete."
}
