Function Uninstall-SSMS {
    <#
    .SYNOPSIS
        Uninstall SSMS
    .DESCRIPTION
        Searches the SSMS versions installed and removes them
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
        Uninstall-SSMS -Confirm
        Uninstalls SSMS. Prompts for confirmation.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param()

    process {
        $filter = 'Microsoft SQL Server Management Studio'
        $uninstall32 = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $filter } | Select-Object UninstallString
        $uninstall64 = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $filter } | Select-Object UninstallString

        if ($uninstall64) {
            $uninstall64 = $uninstall64.UninstallString -Replace "/uninstall", ""
            $uninstall64 = $uninstall64.Trim()
            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Uninstall SSMS')) {
                Write-Output "Uninstalling..."
                Start-Process "$uninstall64" -ArgumentList "/uninstall /quiet /norestart" -Wait -Verb RunAs
            } else {
                Write-Output "This will uninstall SSMS on the $env:COMPUTERNAME."
            }
        }
        if ($uninstall32) {
            $uninstall32 = $uninstall32.UninstallString -Replace "/uninstall", ""
            $uninstall32 = $uninstall32.Trim()
            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Uninstall SSMS')) {
                Write-Output "Uninstalling..."
                Start-Process "$uninstall32" -ArgumentList "/uninstall /quiet /norestart" -Wait -Verb RunAs
            } else {
                Write-Output "This will uninstall SSMS on the $env:COMPUTERNAME."
            }
        }
    }
}
