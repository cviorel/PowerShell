[CmdletBinding()]
param (
    [Parameter()]
    [string]$InstallPath = (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"),
    [switch]$Force,
    [string]$LogPath = (Join-Path $env:TEMP "VSCode-Install.log")
)

# Enhanced logging function
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

function Test-VSCodeInstalled {
    [CmdletBinding()]
    param()

    try {
        $vscodePath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\code.exe"
        $isInstalled = Test-Path $vscodePath

        if ($isInstalled) {
            $version = (Get-Item $vscodePath).VersionInfo.ProductVersion
            return @{
                Installed = $true
                Version   = $version
                Path      = $vscodePath
            }
        }

        return @{
            Installed = $false
            Version   = $null
            Path      = $null
        }
    }
    catch {
        Write-Log -Message "Error checking VS Code installation: $_" -Level Error
        throw
    }
}

function Get-VSCodeLatestVersion {
    [CmdletBinding()]
    param()

    $baseUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"

    try {
        $request = [System.Net.WebRequest]::Create($baseUrl)
        $request.Method = "GET"
        $request.AllowAutoRedirect = $false
        $request.Timeout = 30000

        try {
            $response = $request.GetResponse()
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
                $response = $_.Exception.Response
            }
            else {
                throw
            }
        }

        if ($response -and $response.Headers["Location"]) {
            $downloadUrl = $response.Headers["Location"]
            if ($downloadUrl -match '\d+\.\d+\.\d+') {
                return @{
                    Version = $matches[0]
                    Url     = $downloadUrl
                }
            }
            throw "Could not extract version from download URL: $downloadUrl"
        }
        throw "No redirect URL found"
    }
    catch {
        Write-Log -Message "Failed to get latest VS Code version: $_" -Level Error
        throw
    }
    finally {
        if ($response) {
            $response.Close()
        }
    }
}

function Install-VSCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$InstallerPath,

        [Parameter(Mandatory)]
        [string]$InstallPath
    )

    try {
        Write-Log -Message "Starting VS Code installation..."

        $arguments = @(
            "/VERYSILENT",
            "/NORESTART",
            "/MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,desktopicon,associatewithfiles",
            "/DIR=`"$InstallPath`""
        )

        $process = Start-Process -FilePath $InstallerPath -ArgumentList ($arguments -join ' ') -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }

        $env:Path += ";$installPath\bin"

        Write-Log -Message "Installation completed successfully"
    }
    catch {
        Write-Log -Message "Installation failed: $_" -Level Error
        throw
    }
}

# Main script execution
try {
    Write-Log -Message "Starting VS Code installation script"

    # Check current installation
    $currentInstall = Test-VSCodeInstalled

    if ($currentInstall.Installed -and -not $Force) {
        Write-Log -Message "VS Code is already installed (Version: $($currentInstall.Version))"
        return
    }

    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "VSCodeInstall"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Get latest version
        $vscodeInfo = Get-VSCodeLatestVersion
        Write-Log -Message "Latest VS Code version: $($vscodeInfo.Version)"

        # Download installer
        $installerPath = Join-Path $tempDir "VSCodeSetup.exe"
        $ProgressPreference = 'SilentlyContinue'
        Write-Log -Message "Downloading VS Code installer..."
        Invoke-WebRequest -Uri $vscodeInfo.Url -OutFile $installerPath

        # Install VS Code
        Install-VSCode -InstallerPath $installerPath -InstallPath $InstallPath

        # Verify installation
        $newInstall = Test-VSCodeInstalled
        if ($newInstall.Installed) {
            Write-Log -Message "VS Code $($newInstall.Version) has been successfully installed!"
        }
        else {
            throw "Installation verification failed"
        }
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}
catch {
    Write-Log -Message "Script execution failed: $($_.Exception.Message)" -Level Error
    throw
}
