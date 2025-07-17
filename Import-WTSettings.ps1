<#
.SYNOPSIS
    Import Windows Terminal settings

.DESCRIPTION
    Import Windows Terminal settings

.PARAMETER Path
    Path to backup file

.NOTES
    Author: Viorel Ciucu
    Website: https://cviorel.com
    License: MIT https://opensource.org/licenses/MIT

.EXAMPLE
    Import-WTSettings -Path C:\Temp\wtSettings-2020-03-12T23.33.58.3351871+01.00.zip
#>
function Import-WTSettings {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        $settingsFile = "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\profiles.json"
        $Path = Resolve-Path -Path $Path
        $TempPath = [system.io.path]::GetTempPath()
    }

    process {
        try {
            if ($Pscmdlet.ShouldProcess($TempPath, "Expanding to temp destination")) {
                Expand-Archive -Path $Path -DestinationPath $TempPath -Force
            }
        } catch {
            throw $_
        }

        if (Test-Path -Path $settingsFile) {
            try {
                if ($Pscmdlet.ShouldProcess("File exists, overwrite?")) {
                    Copy-Item -LiteralPath "$TempPath\profiles.json" -Destination $settingsFile -Force
                }
            } catch {
                throw $_
            }
        }
    }
    end {
        Write-Output "The settings file was imported to $settingsFile."
    }
}
