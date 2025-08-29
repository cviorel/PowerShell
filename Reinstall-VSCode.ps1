<#
.SYNOPSIS
This script reinstalls Visual Studio Code using winget.

.DESCRIPTION
The script performs the following steps:
1. Checks if Visual Studio Code (VS Code) is installed.
2. If installed, it closes any running instances of VS Code.
3. Uninstalls VS Code using winget.
4. Cleans up remaining directories related to VS Code.
5. Reinstalls VS Code using winget.

.PARAMETER None
This script does not take any parameters.

.NOTES
File Path: /D:/GitHub/PowerShell/Reinstall-VSCode.ps1

.EXAMPLE
.\Reinstall-VSCode.ps1
This command will execute the script to reinstall Visual Studio Code.

#>
# Store package ID in a variable
$package = "Microsoft.VisualStudioCode"

# Check if VS Code is installed before attempting uninstallation
Write-Host "Checking if $package is installed..." -ForegroundColor Cyan
$installed = winget list --id=$package 2>$null
if ($installed -match $package) {
    # Gracefully close VS Code if it's running
    Write-Host "Closing any running VS Code instances..." -ForegroundColor Cyan
    $vsCodeProcess = Get-Process -Name "code" -ErrorAction SilentlyContinue
    if ($vsCodeProcess) {
        # Try graceful shutdown first
        $vsCodeProcess | ForEach-Object {
            $_ | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Host "VS Code process stopped." -ForegroundColor Green
        }
        # Give processes time to fully terminate
        Start-Sleep -Seconds 2
    }

    # Uninstall using winget
    Write-Host "Uninstalling $package..." -ForegroundColor Cyan
    winget uninstall --id=$package --accept-source-agreements

    # Define paths to clean up
    $paths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"),
        (Join-Path $env:APPDATA "Code"),
        (Join-Path $env:USERPROFILE ".vscode")
    )

    # Clean up remaining directories
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Removing $path..." -ForegroundColor Yellow
            try {
                Remove-Item -Recurse -Force -Path $path -ErrorAction Stop
                Write-Host "Successfully removed $path" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove $path. Error: $_" -ForegroundColor Red
            }
        }
    }
}
else {
    Write-Host "$package is not currently installed." -ForegroundColor Yellow
}

# Install VS Code
Write-Host "Installing $package..." -ForegroundColor Cyan
$installResult = winget install -e --id=$package --accept-source-agreements
if ($installResult -match "Successfully installed") {
    Write-Host "$package was successfully installed!" -ForegroundColor Green
}
else {
    Write-Host "Installation of $package might have failed. Please check the output above." -ForegroundColor Yellow
}
