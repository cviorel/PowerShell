<#
    .SYNOPSIS
        This script invokes the Windows Disk Cleanup utility, enables all rules and runs it.

    .DESCRIPTION
        Invoke-WindowsDiskCleanup configures and runs the Windows Disk Cleanup utility (cleanmgr.exe)
        with all cleanup options enabled. It also optionally cleans up recent items and unused devices.

    .PARAMETER DeviceCleanupPath
        Path to the DeviceCleanupCmd.exe utility. If not specified, the script will use the default path
        or skip device cleanup if the utility is not found.

    .PARAMETER Verbose
        Provides detailed output about the cleanup process.

    .EXAMPLE
        PS> .\Invoke-WindowsDiskCleanup.ps1
        Runs disk cleanup with all default options.

    .EXAMPLE
        PS> .\Invoke-WindowsDiskCleanup.ps1 -DeviceCleanupPath "C:\Tools\DeviceCleanupCmd.exe"
        Runs disk cleanup and uses the specified path for device cleanup.

    .NOTES
        Author: Viorel-Felix Ciucu
        References:
        - https://ss64.com/nt/cleanmgr.html
        - https://ss64.com/nt/cleanmgr-registry.html
        - https://www.uwe-sieber.de/misc_tools_e.html (DeviceCleanupCmd)

        This script requires administrative privileges to modify registry settings.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DeviceCleanupPath = 'D:\Tools\DeviceCleanupCmd\DeviceCleanupCmd.exe'  # Default path to DeviceCleanupCmd.exe
)

# Check for administrative privileges
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "This script requires administrative privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-Verbose ':: Clearing CleanMgr.exe automation settings'

try {
    $getItemParams = @{
        Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
        Name        = 'StateFlags0001'
        ErrorAction = 'SilentlyContinue'
    }
    Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue
    Write-Verbose "Successfully cleared existing cleanup settings"
}
catch {
    Write-Warning "Failed to clear existing cleanup settings: $_"
}

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

Write-Verbose ':: Adding enabled disk cleanup sections...'
$totalSections = $enabledSections.Count
$currentSection = 0

foreach ($keyName in $enabledSections) {
    $currentSection++
    Write-Progress -Activity "Configuring Disk Cleanup" -Status "Setting up section: $keyName" -PercentComplete (($currentSection / $totalSections) * 100)

    try {
        $newItemParams = @{
            Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
            Name         = 'StateFlags0001'
            Value        = 2
            PropertyType = 'DWord'
            ErrorAction  = 'SilentlyContinue'
        }
        $null = New-ItemProperty @newItemParams
        Write-Verbose "Enabled cleanup section: $keyName"
    }
    catch {
        Write-Warning "Failed to enable cleanup section '$keyName': $_"
    }
}

Write-Progress -Activity "Configuring Disk Cleanup" -Completed

Write-Output ':: Starting CleanMgr.exe...'
try {
    Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait
    Write-Verbose "CleanMgr.exe started successfully"
}
catch {
    Write-Error "Failed to start CleanMgr.exe: $_"
    exit 1
}

Write-Output ':: Waiting for CleanMgr and DismHost processes...'
try {
    $cleanupProcesses = Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue
    if ($cleanupProcesses) {
        $cleanupProcesses | ForEach-Object {
            Write-Verbose "Waiting for process: $($_.Name) (ID: $($_.Id))"
        }
        $cleanupProcesses | Wait-Process
    }
    Write-Verbose "All cleanup processes completed"
}
catch {
    Write-Warning "Error while waiting for cleanup processes: $_"
}

Write-Output ":: Clearing recent items"
$directories = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"
)

$totalDirs = $directories.Count
$currentDir = 0

foreach ($directory in $directories) {
    $currentDir++
    Write-Progress -Activity "Clearing Recent Items" -Status "Processing: $directory" -PercentComplete (($currentDir / $totalDirs) * 100)

    if (Test-Path "$directory") {
        try {
            $fileCount = (Get-ChildItem -Path "$directory\*" -File -Force).Count
            Get-ChildItem -Path "$directory\*" -File -Force | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Verbose "Cleared $fileCount files from $directory"
        }
        catch {
            Write-Warning "Failed to clear items from $directory`: $_"
        }
    }
    else {
        Write-Verbose "Directory not found: $directory"
    }
}

Write-Progress -Activity "Clearing Recent Items" -Completed

# Cleaning up unused devices
if ([string]::IsNullOrEmpty($DeviceCleanupPath)) {
    Write-Verbose "DeviceCleanupPath not specified, skipping device cleanup"
}
elseif (Test-Path -Path $DeviceCleanupPath) {
    Write-Output ":: Cleaning up all unused devices from the system"
    try {
        Start-Process -FilePath $DeviceCleanupPath -ArgumentList '-s -n *' -NoNewWindow
        $deviceCleanupProcess = Get-Process -Name DeviceCleanupCmd -ErrorAction SilentlyContinue
        if ($deviceCleanupProcess) {
            Write-Verbose "Waiting for DeviceCleanupCmd process (ID: $($deviceCleanupProcess.Id))"
            $deviceCleanupProcess | Wait-Process
        }
        Write-Output ":: Device cleanup complete"
    }
    catch {
        Write-Warning "Error during device cleanup: $_"
    }
}
else {
    Write-Warning "DeviceCleanupCmd not found at path: $DeviceCleanupPath"
}

Write-Output ":: Disk cleanup completed successfully"
