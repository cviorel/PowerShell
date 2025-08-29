<#
.SYNOPSIS
Clones only a certain directory from a Git Repository

.DESCRIPTION
Clones only a certain directory from a Git Repository

.PARAMETER RepoName
Name of the repository. Eg. https://github.com/cviorel/PowerShell.git

.PARAMETER DirName
Name of the repository. Eg. https://github.com/cviorel/PowerShell.git

.NOTES
https://stackoverflow.com/questions/600079/how-do-i-clone-a-subdirectory-only-of-a-git-repository/52269934#52269934

.EXAMPLE
Invoke-GitSparseCheckout -repoName https://github.com/cviorel/PowerShell.git -dirName 'Hyper-V'

Download folder 'Hyper-V' from the https://github.com/cviorel/PowerShell.git repository

.EXAMPLE
Invoke-GitSparseCheckout -RepoName 'https://github.com/cviorel/PowerShell.git' -DirName OneDrive, 'Hyper-V'

Download folders OneDrive and 'Hyper-V' from the https://github.com/cviorel/PowerShell.git repository

#>

function Invoke-GitSparseCheckout {
    [CmdletBinding()]
    param (
        [string]$RepoName,
        [string[]]$DirName
    )

    begin {
        $git = (Get-Command git).Source
        if ($null -eq $git) {
            Write-Error "Git was not found!"
            exit
        }

        # Get Git version
        $v = git --version
        [regex]$rx = "(\d+\.){1,}\d+"
        $currentVersion = $rx.match($v).Value
        if ($currentVersion -lt '2.19') {
            Write-Warning 'Your version of Git might not support filtering! Consider upgrading it!'
            return
        }
    }

    process {
        git clone --depth 1 --filter=blob:none --sparse $RepoName

        $RepoDir = ($RepoName.Split('/') | Select-Object -Last 1).Split('.') | Select-Object -First 1
        Set-Location -Path $RepoDir
        foreach ($dir in $DirName) {
            git sparse-checkout set $DirName
        }
    }

    end {

    }
}
