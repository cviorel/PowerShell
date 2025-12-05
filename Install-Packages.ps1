#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs a predefined list of packages using winget package manager.

.DESCRIPTION
    This script automates the installation of commonly used applications using
    Windows Package Manager (winget). It automatically checks for already installed
    packages and skips them. It includes error handling, progress tracking,
    and detailed logging of installation results.

.PARAMETER LogPath
    Specifies the path for the installation log file.
    Default: "$env:TEMP\Install-Packages-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

.PARAMETER WhatIf
    Shows what packages would be installed without actually installing them.

.EXAMPLE
    .\Install-Packages.ps1
    Installs packages, automatically skipping already installed ones.

.EXAMPLE
    .\Install-Packages.ps1 -LogPath "C:\Logs\winget-install.log"
    Installs packages with custom log path, skipping already installed ones.

.NOTES
    Author: PowerShell Administrator
    Requires: Windows Package Manager (winget)
    Version: 2.0
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$LogPath = "$env:TEMP\Install-Packages-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

# Initialize logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [ConsoleColor]$ForegroundColor = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console with color
    Write-Host $logEntry -ForegroundColor $ForegroundColor

    # Write to log file
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

# Verify winget is available
function Test-WingetAvailability {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    }
    catch {
        Write-Log "Windows Package Manager (winget) is not available or not in PATH" -Level "ERROR" -ForegroundColor Red
        Write-Log "Please install winget from the Microsoft Store or GitHub releases" -Level "ERROR" -ForegroundColor Red
        return $false
    }
}

# Check if package is already installed
function Test-PackageInstalled {
    param([string]$PackageId)

    try {
        $result = winget list --id $PackageId --exact --source winget 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

# Define the list of packages to install
$packages = @(
    @{ Id = 'Bitwarden.Bitwarden'; Name = 'Bitwarden Password Manager' },
    @{ Id = 'Git.Git'; Name = 'Git Version Control' },
    @{ Id = 'Git.GCM'; Name = 'Git Credential Manager' },
    @{ Id = 'GitHub.cli'; Name = 'GitHub CLI' },
    @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'Oh My Posh Prompt Theme Engine' },
    @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' },
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' },
    @{ Id = 'Notepad++.Notepad++'; Name = 'Notepad++ Text Editor' },
    @{ Id = 'Google.Chrome'; Name = 'Google Chrome Browser' },
    @{ Id = 'Mozilla.Firefox'; Name = 'Mozilla Firefox Browser' },
    @{ Id = 'LibreWolf.LibreWolf'; Name = 'LibreWolf Browser' },
    @{ Id = 'OBSProject.OBSStudio'; Name = 'OBS Studio' },
    @{ Id = 'SlackTechnologies.Slack'; Name = 'Slack Communication' },
    @{ Id = 'Zoom.Zoom'; Name = 'Zoom Video Conferencing' },
    @{ Id = 'Discord.Discord'; Name = 'Discord Chat' },
    @{ Id = 'dotPDN.PaintDotNet'; Name = 'Paint.NET Image Editor' }
    @{ Id = 'VideoLAN.VLC'; Name = 'VLC Media Player' }

    # Additional packages (uncomment as needed)
    # @{ Id = '7zip.7zip'; Name = '7-Zip Archive Manager' },
    # @{ Id = 'AutoHotkey.AutoHotkey'; Name = 'AutoHotkey Automation' },
    # @{ Id = 'XnSoft.XnViewMP'; Name = 'XnView MP Image Viewer' },
    # @{ Id = 'Adobe.Acrobat.Reader.64-bit'; Name = 'Adobe Acrobat Reader DC' }
    )

# Main execution
try {
    Write-Log "Starting package installation process" -Level "INFO" -ForegroundColor Green
    Write-Log "Log file: $LogPath" -Level "INFO"

    # Verify winget availability
    if (-not (Test-WingetAvailability)) {
        exit 1
    }

    # Initialize counters
    $totalPackages = $packages.Count
    $installedCount = 0
    $skippedCount = 0
    $failedCount = 0
    $currentIndex = 0

    # Process each package
    foreach ($package in $packages) {
        $currentIndex++
        $packageId = $package.Id
        $packageName = $package.Name

        Write-Log "[$currentIndex/$totalPackages] Processing: $packageName ($packageId)" -Level "INFO" -ForegroundColor Cyan

        # Check if package is already installed using native winget functionality
        if (Test-PackageInstalled -PackageId $packageId) {
            Write-Log "Package already installed, skipping: $packageName" -Level "SKIP" -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        # Use ShouldProcess for WhatIf support
        if ($PSCmdlet.ShouldProcess($packageName, "Install package")) {
            try {
                # Install package with detailed output
                Write-Log "Installing: $packageName..." -Level "INFO"

                $result = winget install --exact --id=$packageId --silent --accept-package-agreements --accept-source-agreements 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Successfully installed: $packageName" -Level "SUCCESS" -ForegroundColor Green
                    $installedCount++
                }
                else {
                    Write-Log "Installation failed with exit code $LASTEXITCODE for: $packageName" -Level "ERROR" -ForegroundColor Red
                    Write-Log "winget output: $result" -Level "ERROR" -ForegroundColor Red
                    $failedCount++
                }
            }
            catch {
                Write-Log "Exception occurred while installing $packageName`: $($_.Exception.Message)" -Level "ERROR" -ForegroundColor Red
                $failedCount++
            }
        }
        else {
            Write-Log "Would install: $packageName ($packageId)" -Level "WHATIF" -ForegroundColor Magenta
        }

        # Add small delay between installations
        Start-Sleep -Milliseconds 500
    }

    # Final summary
    Write-Log "Package installation completed!" -Level "INFO" -ForegroundColor Green
    Write-Log "Total packages: $totalPackages" -Level "SUMMARY"
    Write-Log "Successfully installed: $installedCount" -Level "SUMMARY" -ForegroundColor Green
    Write-Log "Skipped: $skippedCount" -Level "SUMMARY" -ForegroundColor Yellow
    Write-Log "Failed: $failedCount" -Level "SUMMARY" -ForegroundColor Red

    if ($failedCount -gt 0) {
        Write-Log "Some packages failed to install. Check the log for details: $LogPath" -Level "WARNING" -ForegroundColor Yellow
        exit 1
    }

    exit 0
}
catch {
    Write-Log "Fatal error occurred: $($_.Exception.Message)" -Level "FATAL" -ForegroundColor Red
    exit 1
}
