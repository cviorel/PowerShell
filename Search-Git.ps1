<#
.SYNOPSIS
    Search code on GitHub

.DESCRIPTION
    Search GitHub from the command line.
    Opens a web browser window with the results.

.PARAMETER Language
    You can specify one of these languages:
        'PowerShell', 'Python', 'SQL', 'SQLPL', 'TSQL', 'Shell', 'Markdown', 'YAML'


.EXAMPLE
    Search-Git -Language PowerShell -SearchTerm ADSI

    This will search for PowerShell code containing the term 'ADSI'

.NOTES
    Author: Viorel Ciucu | @viorelciucu | viorel.ciucu@gmail.com
    Copyright (c) 2021 Viorel Ciucu. All rights reserved.
    No warranty or guarantee is implied or expressly granted.

.LINK
    https://github.com/cviorel/PowerShell/blob/main/Search-Git.ps1

.LINK
    https://cviorel.com
#>

function Search-Git {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateSet('PowerShell', 'Python', 'SQL', 'SQLPL', 'TSQL', 'Shell', 'Markdown', 'YAML')]
        [string]$Language,

        [parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchTerm
    )

    begin {
        $baseUrl = 'https://github.com'
    }

    process {
        $query = '/search?q='
        $Language = $Language.Trim()
        $languageStr = 'language%3A' + $Language

        $SearchTerm = $SearchTerm.Trim()
        $searchTermStr = '+' + $SearchTerm
        $url = $baseUrl + $query + $languageStr + $searchTermStr
        Write-Verbose $url
    }

    end {
        Start-Process $url
    }
}
