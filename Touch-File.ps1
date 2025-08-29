<#
.SYNOPSIS
Creates a new file or updates the last modified time of an existing file.

.DESCRIPTION
The Touch-File function mimics the behavior of the Linux 'touch' command in PowerShell.
It creates a new file if it doesn't exist, or updates the last modified time if the file already exists.

.PARAMETER Path
Specifies the path to the file to be touched.

.EXAMPLE
Touch-File "C:\temp\newfile.txt"
# Creates a new file named newfile.txt in C:\temp if it doesn't exist, or updates its last modified time if it does.

.EXAMPLE
Touch-File "existing_file.txt"
# Updates the last modified time of existing_file.txt in the current directory.

.NOTES
Author: Viorel Ciucu
Date: September 8, 2024
#>

function Touch-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [string]$Path
    )

    process {
        try {
            if (Test-Path -Path $Path) {
                # File exists, update last modified time
                (Get-Item $Path).LastWriteTime = Get-Date
                Write-Verbose "Updated last modified time of existing file: $Path"
            }
            else {
                # File doesn't exist, create it
                New-Item -ItemType File -Path $Path | Out-Null
                Write-Verbose "Created new file: $Path"
            }
        }
        catch {
            Write-Error "An error occurred while touching the file: $_"
        }
    }
}
