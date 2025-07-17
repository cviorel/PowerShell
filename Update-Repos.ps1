<#
.SYNOPSIS
    Updates all Git repositories under a specified root folder.

.DESCRIPTION
    The Update-Repos function finds all Git repositories under a specified root folder
    and performs a 'git pull' operation on each of them to update them to the latest version.

.PARAMETER RootFolder
    The path to the root folder containing Git repositories.

.PARAMETER Depth
    The maximum depth to search for Git repositories. Default is 2.

.PARAMETER Parallel
    If specified, updates repositories in parallel using jobs for improved performance.

.EXAMPLE
    Update-Repos -RootFolder "D:\GitHub"
    Updates all Git repositories under D:\GitHub.

.EXAMPLE
    Update-Repos -RootFolder "D:\Projects" -Depth 3 -Parallel
    Updates all Git repositories under D:\Projects with a search depth of 3 in parallel.

.NOTES
    Author: Viorel-Felix Ciucu
#>
function Update-Repos {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "Path to the root folder containing Git repositories")]
        [ValidateNotNullOrEmpty()]
        [string]$RootFolder,

        [Parameter(HelpMessage = "Maximum depth to search for Git repositories")]
        [int]$Depth = 2,

        [Parameter(HelpMessage = "Update repositories in parallel")]
        [switch]$Parallel
    )

    begin {
        # Check if git is available
        try {
            $null = git --version
        }
        catch {
            Write-Error "Git is not installed or not in the PATH. Please install Git or add it to your PATH."
            return
        }

        $originalLocation = Get-Location
    }

    process {
        if (-not (Test-Path -Path $RootFolder -PathType Container)) {
            Write-Error "Cannot find folder: $RootFolder!"
            return
        }

        Write-Verbose "Searching for Git repositories in $RootFolder (max depth: $Depth)..."

        # Find all .git directories
        $gitDirs = Get-ChildItem -Recurse -Depth $Depth -Force -Path $RootFolder -Directory |
                   Where-Object { $_.Name -eq ".git" }

        if (-not $gitDirs) {
            Write-Warning "No Git repositories found in $RootFolder."
            return
        }

        Write-Verbose "Found $($gitDirs.Count) Git repositories."

        # Function to update a single repository
        function Update-SingleRepo {
            param (
                [Parameter(Mandatory = $true)]
                [string]$RepoPath
            )

            $repoName = Split-Path -Path $RepoPath -Leaf
            $parentPath = Split-Path -Path $RepoPath -Parent

            try {
                Push-Location -Path $parentPath
                Write-Output "Updating repository: $repoName"
                $output = git pull 2>&1

                # Check if the pull was successful
                if ($LASTEXITCODE -eq 0) {
                    [PSCustomObject]@{
                        Repository = $repoName
                        Path = $parentPath
                        Status = "Success"
                        Message = $output
                    }
                }
                else {
                    [PSCustomObject]@{
                        Repository = $repoName
                        Path = $parentPath
                        Status = "Failed"
                        Message = $output
                    }
                }
            }
            catch {
                [PSCustomObject]@{
                    Repository = $repoName
                    Path = $parentPath
                    Status = "Error"
                    Message = $_.Exception.Message
                }
            }
            finally {
                Pop-Location
            }
        }

        # Update repositories
        $results = @()

        if ($Parallel) {
            Write-Verbose "Updating repositories in parallel..."
            $jobs = @()

            foreach ($gitDir in $gitDirs) {
                $repoPath = $gitDir.FullName
                $scriptBlock = {
                    param($path)

                    $repoName = Split-Path -Path (Split-Path -Path $path -Parent) -Leaf
                    $parentPath = Split-Path -Path $path -Parent

                    try {
                        Set-Location -Path $parentPath
                        $output = git pull 2>&1

                        if ($LASTEXITCODE -eq 0) {
                            [PSCustomObject]@{
                                Repository = $repoName
                                Path = $parentPath
                                Status = "Success"
                                Message = $output
                            }
                        }
                        else {
                            [PSCustomObject]@{
                                Repository = $repoName
                                Path = $parentPath
                                Status = "Failed"
                                Message = $output
                            }
                        }
                    }
                    catch {
                        [PSCustomObject]@{
                            Repository = $repoName
                            Path = $parentPath
                            Status = "Error"
                            Message = $_.Exception.Message
                        }
                    }
                }

                $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $repoPath
            }

            # Wait for all jobs to complete and collect results
            $results = $jobs | Wait-Job | Receive-Job

            # Clean up jobs
            $jobs | Remove-Job
        }
        else {
            Write-Verbose "Updating repositories sequentially..."
            $total = $gitDirs.Count
            $current = 0

            foreach ($gitDir in $gitDirs) {
                $current++
                $percentComplete = [math]::Round(($current / $total) * 100)
                Write-Progress -Activity "Updating Git Repositories" -Status "$current of $total repositories" -PercentComplete $percentComplete

                $results += Update-SingleRepo -RepoPath $gitDir.FullName
            }

            Write-Progress -Activity "Updating Git Repositories" -Completed
        }

        return $results
    }

    end {
        # Restore original location
        Set-Location -Path $originalLocation
    }
}
