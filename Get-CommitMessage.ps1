<#
.SYNOPSIS
    Generate random commit message

.DESCRIPTION
    Generate random commit message


.NOTES
    Author: Viorel Ciucu
    Website: https://cviorel.com
    GitHub: https://github.com/cviorel
    License: MIT https://opensource.org/licenses/MIT

.EXAMPLE
    ❯ Get-CommitMessage
    this doesn't really make things faster, but I tried
#>
function Get-CommitMessage {
    [CmdletBinding()]
    param (
    )

    begin {

    }

    process {
        $uri = 'http://whatthecommit.com/index.txt'
        $randomCommitMessage = Invoke-RestMethod -Method Get -Uri $uri
        $randomCommitMessage.Trim()
    }

    end {

    }
}
