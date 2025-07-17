<#
.SYNOPSIS
    Download latest Windows Terminal release from github

.DESCRIPTION
    Download latest Windows Terminal release from github

.PARAMETER ReleaseType
    Choose to install between Stable and Preview release

.EXAMPLE
     C:\PS> Get-WindowsTerminal -ReleaseType Stable

     Installs the latest stable release of Windows Terminal

.EXAMPLE
     C:\PS> Get-WindowsTerminal -ReleaseType Preview

     Installs the latest preview release of Windows Terminal

.NOTES
    Author: Viorel Ciucu
    Website: https://cviorel.com
    License: MIT https://opensource.org/licenses/MIT
#>
function Get-WindowsTerminal {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Preview', 'Stable')]
        [string]$ReleaseType
    )

    begin {
        $repo = "microsoft/terminal"
        $releases = "https://api.github.com/repos/$repo/releases"
    }

    process {
        $browser = New-Object System.Net.WebClient
        $browser.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

        $releaseDetail = (Invoke-WebRequest $releases -Headers @{"Accept" = "application/json" } | ConvertFrom-Json)

        $tag = $releaseDetail[0].tag_name

        switch ($ReleaseType) {
            'Preview' {
                $download_url = $releaseDetail[0].assets.browser_download_url | Where-Object { $_ -match $tag -and $_ -match 'WindowsTerminalPreview' }
            }
            'Stable' {
                $download_url = $releaseDetail[0].assets.browser_download_url | Where-Object { $_ -match $tag -and $_ -notmatch 'WindowsTerminalPreview' }
            }
        }

        $file = "Microsoft.WindowsTerminal_${tag}_8wekyb3d8bbwe.msixbundle"

        Write-Output "Dowloading $ReleaseType release, version $tag"
        Invoke-WebRequest $download_url -Out $file

        # Remove existing version and install the new one
        Get-AppxPackage -Name Microsoft.WindowsTerminal | Remove-AppxPackage
        Add-AppxPackage -Path $file
    }

    end {
    }
}
