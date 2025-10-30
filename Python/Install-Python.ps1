<#
.SYNOPSIS
Installs the latest available Python 3 on Windows using winget.

.DESCRIPTION
This script:
- Warns if not running as Administrator.
- Verifies winget availability and guides installation if missing.
- Searches winget for Python.Python 3.x packages and determines the highest available minor version; falls back to Python.Python.3.14 if parsing fails.
- Performs a silent install with license agreements accepted.
- Refreshes PATH in the current session and verifies python and pip.
- Emits clear progress, warning, and error messages.

.INPUTS
None.

.OUTPUTS
None. Writes progress and status to the console. Exits with code 1 on critical failures.

.EXAMPLE
PS> .\Install-Python.ps1
Installs the latest Python 3.x available via winget and verifies python and pip installation.

.NOTES
Requirements:
- Windows with winget (App Installer) installed and internet access.
- Sufficient privileges; elevation recommended for system-wide installation.

Limitations:
- Winget output format may change; version detection relies on parsing search results.
- PATH refresh only affects the current session; a terminal or system restart may still be required for commands to be available everywhere.

.LINK
https://learn.microsoft.com/windows/package-manager/winget/
https://learn.microsoft.com/windows/package-manager/winget/search
https://www.python.org/downloads/windows/
#>

# Install Latest Python on Windows 11 using winget
# This script checks for winget availability and installs the latest Python version

# Check if running with administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host 'Warning: Running without administrator privileges. Installation may require elevation.' -ForegroundColor Yellow
}

# Check if winget is available
Write-Host 'Checking for winget availability...' -ForegroundColor Cyan

try {
    $wingetVersion = winget --version
    Write-Host "winget found: $wingetVersion" -ForegroundColor Green
} catch {
    Write-Host 'Error: winget is not available on this system.' -ForegroundColor Red
    Write-Host 'Please install App Installer from the Microsoft Store or update Windows.' -ForegroundColor Yellow
    exit 1
}

# Search for Python versions
Write-Host "`nSearching for Python packages..." -ForegroundColor Cyan
$searchResults = winget search Python.Python | Out-String

# Extract version numbers to find the latest
Write-Host 'Finding latest Python version...' -ForegroundColor Cyan
$versions = @()
if ($searchResults -match 'Python 3\.(\d+)\s+Python\.Python\.3\.(\d+)\s+3\.(\d+)\.(\d+)') {
    # Parse all Python 3.x versions
    $pattern = 'Python 3\.(\d+)\s+Python\.Python\.3\.\d+\s+3\.(\d+)\.(\d+)'
    $matches = [regex]::Matches($searchResults, $pattern)

    foreach ($match in $matches) {
        $majorMinor = [int]$match.Groups[1].Value
        $versions += $majorMinor
    }

    $latestVersion = ($versions | Measure-Object -Maximum).Maximum
    $packageId = "Python.Python.3.$latestVersion"

    Write-Host "Latest Python version found: 3.$latestVersion" -ForegroundColor Green
} else {
    # Fallback to known latest version
    $packageId = 'Python.Python.3.14'
    Write-Host 'Using Python 3.14 (fallback)' -ForegroundColor Yellow
}

# Install the latest Python
Write-Host "`nInstalling $packageId..." -ForegroundColor Cyan
Write-Host 'This may take a few minutes...' -ForegroundColor Yellow

try {
    # Install Python with silent mode and accept agreements
    winget install $packageId --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nPython installation completed successfully!" -ForegroundColor Green

        # Refresh environment variables
        Write-Host "`nRefreshing environment variables..." -ForegroundColor Cyan
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

        # Verify installation
        Write-Host "`nVerifying Python installation..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2

        try {
            $pythonVersion = python --version
            Write-Host "Python version: $pythonVersion" -ForegroundColor Green

            $pipVersion = pip --version
            Write-Host "pip version: $pipVersion" -ForegroundColor Green
        } catch {
            Write-Host 'Python was installed but may not be in PATH yet.' -ForegroundColor Yellow
            Write-Host 'Please restart your terminal or computer to use Python.' -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nInstallation encountered an issue. Exit code: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "`nError during installation: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nInstallation process complete!" -ForegroundColor Green
Write-Host "If Python commands don't work, try restarting your terminal or computer." -ForegroundColor Yellow
