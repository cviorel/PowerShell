<#
.SYNOPSIS
    Downloads the latest MinGit from GitHub, extracts it to the specified directory, and adds it to the system PATH.
.DESCRIPTION
    This script performs the following actions:
    1. Downloads the latest MinGit release from GitHub
    2. Creates the installation directory if it doesn't exist
    3. Extracts MinGit to the installation directory
    4. Adds the MinGit bin directory to the system PATH
.PARAMETER InstallPath
    The path where MinGit will be installed. If not specified, defaults to "$env:LOCALAPPDATA\Git".
.NOTES
    Requires administrator privileges to modify the system PATH
#>
param(
    [string]$InstallPath = "$env:LOCALAPPDATA\Git"
)

# Ensure we're running as administrator for PATH modification
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges to modify the system PATH."
    Write-Warning "Please restart this script as an administrator."
    exit
}

# Create installation directory if it doesn't exist
$minGitDir = $InstallPath

if (-not (Test-Path -Path $minGitDir)) {
    Write-Host "Creating MinGit installation directory at $minGitDir"
    New-Item -ItemType Directory -Path $minGitDir -Force | Out-Null
}

# Get the latest MinGit release information from GitHub API
Write-Host "Fetching latest MinGit release information..."
$apiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"

try {
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{
        "Accept" = "application/vnd.github.v3+json"
    }

    # Find the MinGit 64-bit zip asset
    $minGitAsset = $releaseInfo.assets | Where-Object {
        $_.name -like "MinGit-*-64-bit.zip" -and $_.name -notlike "*busybox*"
    } | Select-Object -First 1

    if (-not $minGitAsset) {
        throw "Could not find MinGit 64-bit zip asset in the latest release"
    }

    $downloadUrl = $minGitAsset.browser_download_url
    $version = $releaseInfo.tag_name

    Write-Host "Found MinGit version $version"
    Write-Host "Download URL: $downloadUrl"

    # Download the MinGit zip file
    $zipPath = Join-Path $env:TEMP "MinGit.zip"
    Write-Host "Downloading MinGit to $zipPath..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # Extract the zip file to the installation directory
    Write-Host "Extracting MinGit to $minGitDir..."
    Expand-Archive -Path $zipPath -DestinationPath $minGitDir -Force

    # Clean up the temporary zip file
    Remove-Item -Path $zipPath

    # Add MinGit bin directory to the system PATH if it's not already there
    $binPath = Join-Path $minGitDir "cmd"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($currentPath -notlike "*$binPath*") {
        Write-Host "Adding MinGit to system PATH..."
        $newPath = "$currentPath;$binPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Host "MinGit has been added to the system PATH."
    } else {
        Write-Host "MinGit is already in the system PATH."
    }

    Write-Host "MinGit installation completed successfully!"
    Write-Host "MinGit is installed at: $minGitDir"
    Write-Host "You may need to restart your terminal or applications to use git commands."

} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
