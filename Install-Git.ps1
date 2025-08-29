# Script configuration
[CmdletBinding()]
param (
    [Parameter()]
    [string]$InstallPath = (Join-Path $env:LOCALAPPDATA "Programs\Git"),
    [switch]$Force,
    [string]$LogPath = (Join-Path $env:TEMP "Git-Install.log"),
    [switch]$SkipPathUpdate
)

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level = 'Information'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to console with appropriate color
    switch ($Level) {
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        default { Write-Host $logMessage }
    }

    # Append to log file
    $logMessage | Out-File -FilePath $LogPath -Append
}

function Test-GitInstalled {
    try {
        $null = Get-Command git -ErrorAction Stop
        $gitVersion = (git --version 2>&1)
        return $gitVersion -match "git version"
    }
    catch {
        Write-Verbose "Git not found in PATH or not installed"
        return $false
    }
}

function Get-GitLatestVersion {
    $baseUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    try {
        $headers = @{
            'Accept' = 'application/vnd.github.v3+json'
        }

        $release = Invoke-RestMethod -Uri $baseUrl -Method Get -Headers $headers
        $asset = $release.assets |
        Where-Object { $_.name -match '64-bit.exe$' } |
        Select-Object -First 1

        if (-not $asset) {
            throw "Could not find 64-bit Git installer in release assets"
        }

        return [PSCustomObject]@{
            Version = $release.tag_name
            Url     = $asset.browser_download_url
        }
    }
    catch {
        Write-Log -Message "Failed to get latest Git version: $_" -Level Error
        throw
    }

}

function Install-Git {
    param (
        [Parameter(Mandatory)]
        [string]$InstallPath,

        [Parameter(Mandatory)]
        [string]$TempDir
    )

    try {
        # Create temporary directory if it doesn't exist
        if (-not (Test-Path -Path $TempDir)) {
            $null = New-Item -ItemType Directory -Path $TempDir -Force
        }

        # Get latest version info
        Write-Log -Message "Fetching latest Git version information..." -Level Information
        $gitInfo = Get-GitLatestVersion
        $installerPath = Join-Path $TempDir "GitInstaller.exe"

        # Download installer with progress bar
        Write-Log -Message "Downloading Git installer version $($gitInfo.Version)..." -Level Information
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($gitInfo.Url, $installerPath)

        # Verify download
        if (-not (Test-Path $installerPath)) {
            throw "Failed to download Git installer"
        }

        # Install Git
        Write-Log -Message "Installing Git to $InstallPath..." -Level Information
        $installArgs = @(
            "/VERYSILENT",
            "/NORESTART",
            "/NOCANCEL",
            "/SP-",
            "/CLOSEAPPLICATIONS",
            "/RESTARTAPPLICATIONS",
            "/DIR=$InstallPath"
        )

        $process = Start-Process -FilePath $installerPath `
            -ArgumentList $installArgs `
            -Wait `
            -NoNewWindow `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Git installer failed with exit code: $($process.ExitCode)"
        }

        # Update session PATH
        if (-not $SkipPathUpdate) {
            $env:Path += ";$installPath\bin"
        }

        # Verify installation
        if (-not (Test-GitInstalled)) {
            throw "Git installation verification failed"
        }

        Write-Log -Message "Git $($gitInfo.Version) installed successfully!" -Level Information
        git --version
    }
    finally {
        # Cleanup
        if (Test-Path -Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main script execution
try {
    Write-Log -Message "Starting Git installation..."

    if ((Test-GitInstalled) -and -not $Force) {
        Write-Log -Message "Git is already installed:" -Level Information
        git --version
        exit 0
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    Install-Git -InstallPath $InstallPath -TempDir $tempDir
}
catch {
    Write-Log -Message "Script execution failed: $($_.Exception.Message)" -Level Error
    throw
}
