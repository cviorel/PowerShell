#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.SYNOPSIS
    Enables Windows Subsystem for Linux (WSL) prerequisites with enhanced error handling and user experience.

.DESCRIPTION
    This script enables the required Windows features for WSL including:
    - Microsoft-Windows-Subsystem-Linux
    - VirtualMachinePlatform
    - Optionally Microsoft-Hyper-V (on supported editions)

    Features enhanced user experience with progress indicators, logging, countdown timers,
    and comprehensive error handling.

.PARAMETER IncludeHyperV
    Include Hyper-V feature installation (skipped on Home editions).

.PARAMETER AutoRestart
    Automatically restart the computer after feature installation if required.
    Includes a 10-second countdown with cancellation option.

.PARAMETER Force
    Skip confirmation prompts for destructive operations.

.PARAMETER LogPath
    Path for log file. Defaults to %TEMP%\Enable-WslPrerequisites.log

.PARAMETER WhatIf
    Show what would be done without making changes.

.EXAMPLE
    .\Enable-WslPrerequisites-Enhanced.ps1
    Enable WSL prerequisites with interactive prompts.

.EXAMPLE
    .\Enable-WslPrerequisites-Enhanced.ps1 -IncludeHyperV -AutoRestart
    Enable WSL and Hyper-V prerequisites with automatic restart.

.EXAMPLE
    .\Enable-WslPrerequisites-Enhanced.ps1 -WhatIf
    Preview what changes would be made.

.NOTES
    Author: Enhanced Version
    Version: 2.0
    Requires: PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
param(
    [Parameter(HelpMessage = "Include Hyper-V feature installation")]
    [switch]$IncludeHyperV,

    [Parameter(HelpMessage = "Automatically restart if required (with countdown)")]
    [switch]$AutoRestart,

    [Parameter(HelpMessage = "Skip confirmation prompts")]
    [switch]$Force,

    [Parameter(HelpMessage = "Path for log file")]
    [ValidateScript({
        $dir = Split-Path $_ -Parent
        if ($dir -and !(Test-Path $dir)) {
            throw "Directory '$dir' does not exist"
        }
        $true
    })]
    [string]$LogPath = "$env:TEMP\Enable-WslPrerequisites.log"
)

# Script configuration
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

# Constants
$WSL_FEATURES = @{
    'Microsoft-Windows-Subsystem-Linux' = 'Windows Subsystem for Linux'
    'VirtualMachinePlatform' = 'Virtual Machine Platform'
}

$HYPERV_FEATURE = @{
    'Microsoft-Hyper-V' = 'Hyper-V Platform'
}

$EXIT_CODES = @{
    Success = 0
    GeneralError = 1
    RebootRequired = 3010
    UserCancelled = 1223
    InsufficientPrivileges = 5
    UnsupportedOS = 50
}

# Global variables
$script:LogInitialized = $false
$script:RebootRequired = $false

#region Logging Functions

function Initialize-Logging {
    [CmdletBinding()]
    param([string]$Path)

    try {
        $logDir = Split-Path $Path -Parent
        if ($logDir -and !(Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $header = @"
================================================================================
WSL Prerequisites Installation Log
Started: $timestamp
User: $env:USERNAME
Computer: $env:COMPUTERNAME
PowerShell Version: $($PSVersionTable.PSVersion)
OS Version: $([System.Environment]::OSVersion.VersionString)
================================================================================

"@
        $header | Out-File -FilePath $Path -Encoding UTF8
        $script:LogInitialized = $true
        Write-Verbose "Logging initialized: $Path"
    }
    catch {
        Write-Warning "Failed to initialize logging: $($_.Exception.Message)"
    }
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    if ($script:LogInitialized) {
        try {
            $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to write to log: $($_.Exception.Message)"
        }
    }

    switch ($Level) {
        'ERROR' { Write-Error $Message -ErrorAction Continue }
        'WARN'  { Write-Warning $Message }
        'DEBUG' { Write-Debug $Message }
        default { Write-Verbose $Message }
    }
}

#endregion

#region System Validation Functions

function Test-SystemCompatibility {
    [CmdletBinding()]
    param()

    Write-Log "Checking system compatibility..."

    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    $minVersion = [Version]"10.0.19041"  # Windows 10 version 2004

    if ($osVersion -lt $minVersion) {
        $message = "Windows version $($osVersion) is not supported. Minimum required: $minVersion (Windows 10 version 2004)"
        Write-Log $message -Level ERROR
        throw $message
    }

    # Check if running as administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $message = "This script must be run as Administrator"
        Write-Log $message -Level ERROR
        throw $message
    }

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $message = "PowerShell version $($PSVersionTable.PSVersion) is not supported. Minimum required: 5.1"
        Write-Log $message -Level ERROR
        throw $message
    }

    Write-Log "System compatibility check passed"
}

function Get-WindowsEditionInfo {
    [CmdletBinding()]
    param()

    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $versionInfo = Get-ItemProperty -Path $regPath -ErrorAction Stop

        $editionInfo = @{
            EditionID = $versionInfo.EditionID
            ProductName = $versionInfo.ProductName
            BuildNumber = $versionInfo.CurrentBuildNumber
            IsHomeEdition = $versionInfo.EditionID -match 'Core|Home'
            SupportsHyperV = $versionInfo.EditionID -notmatch 'Core|Home'
        }

        Write-Log "Windows Edition: $($editionInfo.ProductName) ($($editionInfo.EditionID))"
        Write-Log "Build Number: $($editionInfo.BuildNumber)"

        return $editionInfo
    }
    catch {
        Write-Log "Failed to get Windows edition information: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

#endregion

#region Feature Management Functions

function Get-FeatureStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName
    )

    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        return @{
            Name = $FeatureName
            State = $feature.State
            IsEnabled = $feature.State -in @('Enabled', 'EnablePending')
            RestartRequired = $feature.State -eq 'EnablePending'
        }
    }
    catch {
        Write-Log "Failed to get status for feature '$FeatureName': $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Enable-WindowsFeatureWithProgress {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$FeatureName,

        [Parameter(Mandatory)]
        [string]$DisplayName,

        [switch]$All
    )

    $status = Get-FeatureStatus -FeatureName $FeatureName

    if ($status.IsEnabled) {
        $statusText = if ($status.RestartRequired) { "enabled (restart pending)" } else { "already enabled" }
        Write-Log "Feature '$DisplayName' is $statusText"
        Write-Host "✓ $DisplayName is $statusText" -ForegroundColor Green
        return $status.RestartRequired
    }

    if ($PSCmdlet.ShouldProcess($DisplayName, 'Enable Windows feature')) {
        try {
            Write-Host "⏳ Enabling $DisplayName..." -ForegroundColor Yellow
            Write-Log "Enabling feature: $FeatureName"

            $enableArgs = @{
                Online = $true
                FeatureName = $FeatureName
                NoRestart = $true
                ErrorAction = 'Stop'
            }

            if ($All) {
                $enableArgs.All = $true
            }

            $result = Enable-WindowsOptionalFeature @enableArgs

            $restartNeeded = [bool]$result.RestartNeeded
            $statusText = if ($restartNeeded) { "enabled (restart required)" } else { "enabled" }

            Write-Host "✓ $DisplayName $statusText" -ForegroundColor Green
            Write-Log "Feature '$FeatureName' enabled successfully. Restart needed: $restartNeeded"

            return $restartNeeded
        }
        catch {
            $errorMsg = "Failed to enable '$DisplayName': $($_.Exception.Message)"
            Write-Log $errorMsg -Level ERROR
            Write-Host "✗ $errorMsg" -ForegroundColor Red
            throw
        }
    }

    return $false
}

#endregion

#region Restart Management Functions

function Show-RestartCountdown {
    [CmdletBinding()]
    param(
        [int]$Seconds = 10
    )

    Write-Host "`n" -NoNewline
    Write-Host "⚠️  SYSTEM RESTART REQUIRED" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "The system will restart automatically in $Seconds seconds to complete feature installation." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C or any key to cancel automatic restart..." -ForegroundColor Cyan
    Write-Host ""

    Write-Log "Starting $Seconds second restart countdown"

    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host "`r⏰ Restarting in $i seconds... (Press any key to cancel)" -NoNewline -ForegroundColor Yellow

        # Check for key press
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            Write-Host "`n"
            Write-Host "🛑 Automatic restart cancelled by user" -ForegroundColor Green
            Write-Log "Automatic restart cancelled by user (key pressed: $($key.Key))"
            return $false
        }

        Start-Sleep -Seconds 1
    }

    Write-Host "`n"
    Write-Log "Countdown completed, proceeding with restart"
    return $true
}

function Invoke-SystemRestart {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )

    if (-not $Force) {
        Write-Host "`n🔄 A system restart is required to complete the installation." -ForegroundColor Yellow
        $response = Read-Host "Do you want to restart now? (y/N)"

        if ($response -notmatch '^[Yy]') {
            Write-Host "ℹ️  Please restart your computer manually to complete the installation." -ForegroundColor Cyan
            Write-Log "User declined manual restart"
            return $false
        }
    }

    if ($PSCmdlet.ShouldProcess("System", "Restart computer")) {
        try {
            Write-Host "🔄 Restarting system..." -ForegroundColor Green
            Write-Log "Initiating system restart"
            Restart-Computer -Force
            return $true
        }
        catch {
            Write-Log "Failed to restart system: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }

    return $false
}

#endregion

#region Main Functions

function Install-WslPrerequisites {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Host "🚀 Installing WSL Prerequisites" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan

    $script:RebootRequired = $false

    # Install core WSL features
    foreach ($feature in $WSL_FEATURES.GetEnumerator()) {
        $restartNeeded = Enable-WindowsFeatureWithProgress -FeatureName $feature.Key -DisplayName $feature.Value
        $script:RebootRequired = $script:RebootRequired -or $restartNeeded
    }

    # Install Hyper-V if requested and supported
    if ($IncludeHyperV) {
        $editionInfo = Get-WindowsEditionInfo

        if ($editionInfo.SupportsHyperV) {
            foreach ($feature in $HYPERV_FEATURE.GetEnumerator()) {
                $restartNeeded = Enable-WindowsFeatureWithProgress -FeatureName $feature.Key -DisplayName $feature.Value -All
                $script:RebootRequired = $script:RebootRequired -or $restartNeeded
            }
        }
        else {
            Write-Host "⚠️  Skipping Hyper-V: Not supported on $($editionInfo.ProductName)" -ForegroundColor Yellow
            Write-Log "Hyper-V installation skipped: Not supported on $($editionInfo.EditionID)" -Level WARN
        }
    }
}

function Show-CompletionSummary {
    [CmdletBinding()]
    param()

    Write-Host "`n" -NoNewline
    Write-Host "📋 INSTALLATION SUMMARY" -ForegroundColor Green -BackgroundColor Black
    Write-Host "========================" -ForegroundColor Green

    # Show feature status
    $allFeatures = $WSL_FEATURES.Clone()
    if ($IncludeHyperV) {
        $editionInfo = Get-WindowsEditionInfo
        if ($editionInfo.SupportsHyperV) {
            $allFeatures += $HYPERV_FEATURE
        }
    }

    foreach ($feature in $allFeatures.GetEnumerator()) {
        try {
            $status = Get-FeatureStatus -FeatureName $feature.Key
            $statusIcon = if ($status.IsEnabled) { "✓" } else { "✗" }
            $statusColor = if ($status.IsEnabled) { "Green" } else { "Red" }
            $statusText = if ($status.RestartRequired) { "$($status.State) (restart pending)" } else { $status.State }

            Write-Host "$statusIcon $($feature.Value): $statusText" -ForegroundColor $statusColor
        }
        catch {
            Write-Host "✗ $($feature.Value): Error checking status" -ForegroundColor Red
        }
    }

    if ($script:RebootRequired) {
        Write-Host "`n🔄 System restart is required to complete installation" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n✅ All features installed successfully - no restart required" -ForegroundColor Green
    }

    Write-Host "`n📝 Log file: $LogPath" -ForegroundColor Cyan
}

#endregion

#region Main Execution

try {
    # Initialize logging
    Initialize-Logging -Path $LogPath
    Write-Log "Script started with parameters: IncludeHyperV=$IncludeHyperV, AutoRestart=$AutoRestart, Force=$Force"

    # Validate system compatibility
    Test-SystemCompatibility

    # Install prerequisites
    Install-WslPrerequisites

    # Show completion summary
    Show-CompletionSummary

    # Handle restart if required
    if ($script:RebootRequired) {
        Write-Log "Restart required to complete installation"

        if ($AutoRestart) {
            if ($Force -or (Show-RestartCountdown -Seconds 10)) {
                Invoke-SystemRestart -Force:$Force
                exit $EXIT_CODES.RebootRequired
            }
            else {
                Write-Host "ℹ️  Please restart your computer manually to complete the installation." -ForegroundColor Cyan
                Write-Log "User cancelled automatic restart"
                exit $EXIT_CODES.RebootRequired
            }
        }
        else {
            $restarted = Invoke-SystemRestart -Force:$Force
            if (-not $restarted) {
                exit $EXIT_CODES.RebootRequired
            }
        }
    }

    Write-Log "Script completed successfully"
    exit $EXIT_CODES.Success
}
catch {
    $errorMessage = "Script failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level ERROR
    Write-Host "❌ $errorMessage" -ForegroundColor Red

    # Determine appropriate exit code
    $exitCode = switch -Regex ($_.Exception.Message) {
        "Administrator|privilege" { $EXIT_CODES.InsufficientPrivileges }
        "Windows version|not supported" { $EXIT_CODES.UnsupportedOS }
        "cancelled|abort" { $EXIT_CODES.UserCancelled }
        default { $EXIT_CODES.GeneralError }
    }

    Write-Log "Exiting with code: $exitCode"
    exit $exitCode
}
finally {
    if ($script:LogInitialized) {
        Write-Log "Script execution completed"
    }
}

#endregion
