function Get-RepoForks {
    <#
    .DESCRIPTION
    Function to list forks for a GitHub repository

    .PARAMETER OrgName
    The name of the Organisation that ownd the repository

    .PARAMETER RepoName
    The name of the repository

    .EXAMPLE
    Get-RepoForks -OrgName 'BrentOzarULTD' -RepoName 'SQL-Server-First-Responder-Kit'

    Gets all the forks for SQL-Server-First-Responder-Kit, sorted by updated_at

    .EXAMPLE
    Get-RepoForks -OrgName 'BrentOzarULTD' -RepoName 'SQL-Server-First-Responder-Kit' | Select-Object -First 5 | Format-Table -AutoSize

    Gets 5 forks for SQL-Server-First-Responder-Kit, sorted by updated_at
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OrgName,

        [Parameter(Mandatory = $true)]
        [string]$RepoName
    )

    begin {

    }

    process {
        $forks_url = "https://api.github.com/repos/${OrgName}/${RepoName}/forks"
        $forks = Invoke-WebRequest -UseBasicParsing $forks_url -Headers @{"Accept" = "application/json" }

        $json = $forks.Content | ConvertFrom-Json

        $json | Select-Object full_name, private, html_url, created_at, updated_at, pushed_at | Sort-Object -Property updated_at -Descending
    }

    end {

    }
}
