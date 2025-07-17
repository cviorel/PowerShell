<#
.SYNOPSIS
    Update the local executable packer.exe

.DESCRIPTION
    Update the local executable packer.exe
    If an existing version is found it will be replaced with the latest available version.

.NOTES
    Author: Viorel Ciucu
    Website: https://cviorel.com
    GitHub: https://github.com/cviorel
    License: MIT https://opensource.org/licenses/MIT

.EXAMPLE
    ❯ Get-Packer -LocalPath C:\HashiCorp
    You already have the latest version of packer!

    .EXAMPLE
    ❯ Get-Packer -LocalPath C:\HashiCorp\
    Your version of Packer is out of date!
    Downloading Packer 1.6.5 for amd64!
#>

function Get-Packer {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$LocalPath
    )

    Set-StrictMode -Version 3.0
    $ErrorActionPreference = "Stop"

    # Setting Tls to 12 to prevent the Invoke-WebRequest : The request was
    # aborted: Could not create SSL/TLS secure channel. error.
    $originalValue = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { $tf_arch = 'amd64' }
        "x86" { $tf_arch = '386' }
        default { throw "packer package for OS architecture '$_' is not supported." }
    }

    if (-not (Test-Path -Path $LocalPath)) {
        New-Item -Path $localPath -ItemType Directory -ErrorAction SilentlyContinue
    }

    # Check if last "\" was provided in $localPath, if it was not, add it
    if (-not $LocalPath.EndsWith("\")) {
        $LocalPath = $LocalPath + "\"
    }

    $tf_release_url = 'https://releases.hashicorp.com/packer/index.json'

    try {
        $response = Invoke-WebRequest -Uri $tf_release_url -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        # Try with default proxy and usersettings
        (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $response = Invoke-WebRequest -Uri $tf_release_url -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json
    }

    # Get current packer version
    $obj = $response.versions

    $versions = $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        [PSCustomObject]@{
            Key   = $key;
            Value = $obj."$key"
        }
    }

    [regex]$regex = '\d+\.\d+\.\d+$'
    $latestVersion = ($versions.Key -match $regex | ForEach-Object { [System.Version]$_ } | Sort-Object -Descending | Select-Object -First 1 | Select-Object -Property @{ Name = 'Version'; Expression = { ($_.Major, $_.Minor, $_.Build) -join ('.') } }).Version

    # Build packer command and run it
    $command = "$LocalPath" + "packer.exe"

    if (Test-Path -Path $command) {
        $currentLocation = Get-Location
        Set-Location -Path "$LocalPath"
        $version = $(&$command -version).Split([Environment]::NewLine) | Select-Object -First 1 | Write-Output
        Set-Location -Path $currentLocation
        # Match and return versions
        [string]$version -match $regex | Out-Null
        if (Test-Path variable:Matches) {
            $installedVersion = $Matches[0]
        }
    }
    else {
        $installedVersion = $null
    }

    # We need to update
    if ($installedVersion -ne $latestVersion) {
        Write-Output "Your version of Packer is out of date!"
        $url = "https://releases.hashicorp.com/packer/$($latestVersion)/packer_$($latestVersion)_windows_$tf_arch.zip"
        $temp = ([System.IO.Path]::GetTempPath()).TrimEnd("\")
        $zipfile = "$temp\packer.zip"
        $zipfolder = "$temp\packer\"
        if ($zipfile | Test-Path) {
            Remove-Item -Path $zipfile -ErrorAction SilentlyContinue
        }
        if ($zipfolder | Test-Path) {
            Remove-Item -Path $zipfolder -Recurse -ErrorAction SilentlyContinue
        }
        $null = New-Item -ItemType Directory -Path $zipfolder -ErrorAction SilentlyContinue

        Write-Output "Downloading Packer $latestVersion for $tf_arch!"
        if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
            # On Windows PowerShell, progress can make the download significantly slower
            $oldProgressPreference = $ProgressPreference
            $ProgressPreference = "SilentlyContinue"
        }

        try {
            Invoke-WebRequest -Uri $url -OutFile $zipfile -ErrorAction Stop -UseBasicParsing
        }
        catch {
            # try with default proxy and usersettings
            (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
            Invoke-WebRequest -Uri $url -OutFile $zipfile -ErrorAction Stop -UseBasicParsing
        }
        finally {
            if (!$PSVersionTable.ContainsKey('PSEdition') -or $PSVersionTable.PSEdition -eq "Desktop") {
                $ProgressPreference = $oldProgressPreference
            }
        }

        Unblock-File $zipFile -ErrorAction SilentlyContinue
        Expand-Archive -Path $zipFile -DestinationPath $zipfolder -Force
        Copy-Item -Path "$zipfolder\packer.exe" -Destination $LocalPath -Force

        # Cleanup
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item $zipfolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Output 'You already have the latest version of Packer!'
    }

    # Restore original value
    [Net.ServicePointManager]::SecurityProtocol = $originalValue
}
