Function Install-SSMS {
    <#
    .SYNOPSIS
        Silently Download and Install SQL Server Management Studio (SSMS).

    .DESCRIPTION
        This will download and install the latest available SSMS from Microsoft.

    .PARAMETER DoNotInstallAzureDataStudio
        This will prevent the installation of Azure Data Studio

    .PARAMETER WriteLog
        You want to log to a file. It will generate more than a few files :)

    .PARAMETER RemoveDownload
        Removes the downloaded file after the installation.

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Author: Viorel Ciucu
        Website: https://cviorel.com
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://www.cviorel.com/2017/01/27/silently-download-and-install-sql-server-management-studio-ssms/

    .EXAMPLE
        Install-SSMS -WriteLog 1
        Silently downloads and installs latest version of SSMS.
        It will create a log for the installation.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param (
        [parameter(Mandatory = $false)]
        [string]$LocalFile,

        [parameter(Mandatory = $false)]
        [bool]$DoNotInstallAzureDataStudio = $false,

        [parameter(Mandatory = $false)]
        [bool]$WriteLog = $false,

        [parameter(Mandatory = $false)]
        [bool]$RemoveDownload = $false
    )

    $argList = @()
    $argList += "/install /quiet /norestart"

    $temp = ([System.IO.Path]::GetTempPath()).TrimEnd("\")
    $outFile = "$temp\SSMS-Setup-ENU.exe"

    if ($DoNotInstallAzureDataStudio -eq $true) {
        $argList += "DoNotInstallAzureDataStudio=1"
    }

    if ($WriteLog -eq $true) {
        $logFile = "$temp\SSMS_$(Get-Date -Format `"yyyyMMddHHmm`").txt"
        $argList += "/log $logFile"
        Write-Output "InstallationLog: $logFile"
    }

    if ($LocalFile -eq $null -or $LocalFile.Length -eq 0) {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Downloading latest SSMS to $outFile")) {
            try {
                # Create SSL/TLS secure channel
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                # Start the download
                $url = "https://aka.ms/ssmsfullsetup"

                try {
                    $ProgressPreference = "SilentlyContinue"
                    Invoke-WebRequest $url -OutFile $outFile -UseBasicParsing
                }
                catch {
                    (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    Invoke-WebRequest $url -OutFile $outFile -UseBasicParsing
                }
            }
            catch {
                Write-Output "Download failed. Please download manually from $url."
                return
            }
        }
    }
    else {
        $outFile = $LocalFile
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Installing latest SSMS from $outFile")) {
        # Closing running SSMS processes
        if (Get-Process 'Ssms' -ErrorAction SilentlyContinue) {
            Stop-Process -Name Ssms -Force -ErrorAction SilentlyContinue
        }

        # Install silently
        if (Test-Path $outFile) {
            if ($outFile.EndsWith("exe")) {
                Write-Output "Performing silent install..."
                $process = Start-Process -FilePath $outFile -ArgumentList $argList -Wait -Verb RunAs -PassThru

                if ($process.ExitCode -ne 0) {
                    Write-Output "$_ exited with status code $($process.ExitCode). Check the error code here: https://docs.microsoft.com/en-us/windows/win32/msi/error-codes"
                }
                else {
                    Write-Output "Instalation was sucessfull!"
                }
            }
        }
        else {
            Write-Output "$outFile does not exist. Probably the download failed."
        }
    }

    # Cleanup
    if ($RemoveDownload -eq $true) {
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Removing the installation file $outFile")) {
            Remove-Item $outFile -Force -ErrorAction SilentlyContinue
        }
    }
}
