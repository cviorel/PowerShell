# https://gist.github.com/aaroncalderon/09a2833831c0f3a3bb57fe2224963942

<#

    .Synopsis
    Converts a PowerShell object to a Markdown table.

    .Description
    Converts a PowerShell object to a Markdown table.

    .Parameter InputObject
    PowerShell object to be converted

    .Example
    ConvertTo-Markdown -InputObject (Get-Service)

    Converts a list of running services on the local machine to a Markdown table

    .Example
    ConvertTo-Markdown -InputObject (Import-CSV "C:\Scratch\lwsmachines.csv") | Out-File "C:\Scratch\file.markdown" -Encoding "ASCII"

    Converts a CSV file to a Markdown table

    .Example
    Import-CSV "C:\Scratch\lwsmachines.csv" | ConvertTo-Markdown | Out-File "C:\Scratch\file2.markdown" -Encoding "ASCII"

    Converts a CSV file to a markdown table via the pipeline.

    .Notes
    Ben Neise 10/09/14
    Aaron Calderon 06/09/2016 Added new line `n on each line printed

    #>
Function ConvertTo-Markdown {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]$collection
    )

    Begin {
        $items = @()
        $columns = @{}
    }

    Process {
        ForEach ($item in $collection) {
            $items += $item

            $item.PSObject.Properties | ForEach-Object {
                if ($_.Value -eq $null) {
                    $_.Value = ""
                }
                if (-not $columns.ContainsKey($_.Name) -or $columns[$_.Name] -lt $_.Value.ToString().Length) {
                    $columns[$_.Name] = $_.Value.ToString().Length
                }
            }
        }
    }

    End {
        ForEach ($key in $($columns.Keys)) {
            $columns[$key] = [Math]::Max($columns[$key], $key.Length)
        }

        $header = @()
        ForEach ($key in $columns.Keys) {
            $header += ('{0,-' + $columns[$key] + '}') -f $key
        }
        $($header -join ' | ') + "`n"

        $separator = @()
        ForEach ($key in $columns.Keys) {
            $separator += '-' * $columns[$key]
        }
        $($separator -join ' | ') + "`n"


        ForEach ($item in $items) {
            $values = @()
            ForEach ($key in $columns.Keys) {
                $values += ('{0,-' + $columns[$key] + '}') -f $item.($key)
            }
            $($values -join ' | ') + "`n"
        }
    }
}
