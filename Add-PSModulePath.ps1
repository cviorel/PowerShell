<#
.SYNOPSIS
    Adds a specified directory to the PSModulePath environment variable.

.DESCRIPTION
    This function accepts a directory path and checks if it's already present in the $env:PSModulePath.
    If the path is not present, it adds the path to the beginning of the PSModulePath, ensuring that
    PowerShell modules in that directory can be found. If the path already exists, no changes are made.

.PARAMETER PathToAdd
    The full directory path that you want to add to the PSModulePath environment variable. This is a
    mandatory parameter and must point to an existing directory.

.EXAMPLE
    Add-PSModulePath -PathToAdd "C:\MyModules"
    Adds "C:\MyModules" to the PSModulePath if it's not already present.

.EXAMPLE
    Add-PSModulePath -PathToAdd "D:\OtherModules"
    Adds "D:\OtherModules" to the PSModulePath if it's not already present.

.NOTES
    Author: Viorel Ciucu
    Date: 2024-09-19
    This function is useful for dynamically managing PowerShell module directories in your environment.
#>
function Add-PSModulePath {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })] # Ensure the path exists before proceeding
        [string]$PathToAdd
    )

    try {
        # Get the full path and remove trailing backslash
        $PathToAdd = (Get-Item -Path $PathToAdd | Select-Object -ExpandProperty FullName).TrimEnd('\')

        # Check if the path is already in $env:PSModulePath
        if (-not ($env:PSModulePath -split ';' | ForEach-Object { $_.TrimEnd('\') } | Where-Object { $_ -eq $PathToAdd })) {
            # If not, add it to the beginning of $env:PSModulePath
            $env:PSModulePath = "$PathToAdd;$env:PSModulePath"
            Write-Output "Path added to PSModulePath: $PathToAdd"
        }
        else {
            Write-Output "Path already exists in PSModulePath: $PathToAdd"
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
