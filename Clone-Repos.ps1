<#
.SYNOPSIS
    Clones GitHub repositories for a specified user with advanced filtering and error handling.

.DESCRIPTION
    The Clone-Repos function retrieves and clones GitHub repositories for a specified user.
    It supports filtering by repository visibility (public, private, or both), handles authentication
    securely, and provides comprehensive error handling and progress reporting.

.PARAMETER Username
    The GitHub username whose repositories will be cloned.
    Must be a valid GitHub username (alphanumeric characters, hyphens allowed).

.PARAMETER Visibility
    Specifies which repositories to clone based on visibility.
    Valid values: "public", "private", "both"
    Default: "both"

.PARAMETER DestinationPath
    The directory where repositories will be cloned.
    If not specified, uses the current directory.
    The directory will be created if it doesn't exist.

.PARAMETER IncludeForks
    If specified, includes forked repositories in the clone operation.
    By default, forks are excluded from public repositories but included for private repositories.

.PARAMETER Token
    GitHub personal access token for authentication.
    If not provided, the script will check for GH_TOKEN environment variable or prompt for input.


.EXAMPLE
    Clone-Repos -Username "octocat"
    Clones all public and private repositories for user "octocat" to the current directory.

.EXAMPLE
    Clone-Repos -Username "octocat" -Visibility "public" -DestinationPath "C:\GitHub"
    Clones only public repositories for user "octocat" to C:\GitHub directory.

.EXAMPLE
    Clone-Repos -Username "octocat" -IncludeForks -WhatIf
    Shows what repositories (including forks) would be cloned without actually cloning them.

.NOTES
    Author: Viorel-Felix Ciucu
    Requires: GitHub CLI (gh) to be installed and available in PATH
    Version: 2.0

    Prerequisites:
    - GitHub CLI must be installed
    - Valid GitHub personal access token (for private repositories)
    - Network connectivity to GitHub

.LINK
    https://cli.github.com/
#>

function Clone-Repos {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "GitHub username whose repositories will be cloned")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$')]
        [string]$Username,

        [Parameter(HelpMessage = "Repository visibility filter: public, private, or both")]
        [ValidateSet("public", "private", "both")]
        [string]$Visibility = "both",

        [Parameter(HelpMessage = "Destination directory for cloned repositories")]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath = (Get-Location).Path,

        [Parameter(HelpMessage = "Include forked repositories in the clone operation")]
        [switch]$IncludeForks,

        [Parameter(HelpMessage = "GitHub personal access token for authentication")]
        [SecureString]$Token
    )

    begin {
        Write-Verbose "Starting Clone-Repos function for user: $Username"

        # Store original location for cleanup
        $originalLocation = Get-Location
        $clonedRepos = @()
        $failedRepos = @()

        # Validate prerequisites
        if (-not (Test-GitHubCLI)) {
            return
        }

        # Handle authentication
        if (-not (Initialize-GitHubAuthentication -Token $Token)) {
            return
        }

        # Validate and create destination directory
        if (-not (Initialize-DestinationDirectory -Path $DestinationPath)) {
            return
        }
    }

    process {
        try {
            Write-Host "Fetching repository information for user '$Username'..." -ForegroundColor Cyan

            # Get repositories based on visibility
            $repositories = Get-UserRepositories -Username $Username -Visibility $Visibility -IncludeForks:$IncludeForks

            if (-not $repositories -or $repositories.Count -eq 0) {
                Write-Warning "No repositories found for user '$Username' with the specified criteria."
                return
            }

            Write-Host "Found $($repositories.Count) repositories to process" -ForegroundColor Green

            if ($WhatIfPreference) {
                Write-Host "`nRepositories that would be cloned:" -ForegroundColor Yellow
                $repositories | ForEach-Object {
                    $forkStatus = if ($_.isFork) { " (fork)" } else { "" }
                    Write-Host "  - $($_.name)$forkStatus" -ForegroundColor White
                }
                return
            }

            # Clone repositories
            $results = Invoke-RepositoryCloning -Repositories $repositories -DestinationPath $DestinationPath

            # Display summary
            Show-CloningSummary -Results $results

            return $results
        }
        catch {
            Write-Error "An unexpected error occurred: $($_.Exception.Message)"
            Write-Verbose "Full error details: $($_.Exception | Format-List * | Out-String)"
        }
    }

    end {
        # Cleanup: Clear sensitive environment variables
        if ($env:GH_TOKEN_TEMP) {
            Remove-Item Env:GH_TOKEN_TEMP -ErrorAction SilentlyContinue
        }

        # Restore original location
        try {
            Set-Location -Path $originalLocation -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "Could not restore original location: $($_.Exception.Message)"
        }

        Write-Verbose "Clone-Repos function completed"
    }
}

#region Helper Functions

function Test-GitHubCLI {
    <#
    .SYNOPSIS
    Validates that GitHub CLI is installed and available.
    #>
    try {
        $ghVersion = gh --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "GitHub CLI returned non-zero exit code"
        }
        Write-Verbose "GitHub CLI is available: $($ghVersion[0])"
        return $true
    }
    catch {
        Write-Error "GitHub CLI (gh) is not installed or not available in PATH."
        Write-Error "Please install GitHub CLI from: https://cli.github.com/"
        return $false
    }
}

function Initialize-GitHubAuthentication {
    <#
    .SYNOPSIS
    Handles GitHub authentication with secure token management.
    #>
    param(
        [SecureString]$Token
    )

    # Check if already authenticated
    try {
        $authStatus = gh auth status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Already authenticated with GitHub CLI"
            return $true
        }
    }
    catch {
        Write-Verbose "Not currently authenticated with GitHub CLI"
    }

    # Check for existing environment variable
    if ($env:GH_TOKEN) {
        Write-Verbose "Using existing GH_TOKEN environment variable"
        return $true
    }

    # Use provided token or prompt for one
    if ($Token) {
        $tokenString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token))
    }
    else {
        Write-Host "GitHub authentication required." -ForegroundColor Yellow
        $secureToken = Read-Host -Prompt 'Enter your GitHub personal access token' -AsSecureString
        $tokenString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken))
    }

    if ([string]::IsNullOrWhiteSpace($tokenString)) {
        Write-Error "GitHub token is required for authentication."
        return $false
    }

    # Set temporary environment variable
    $env:GH_TOKEN_TEMP = $tokenString
    $env:GH_TOKEN = $tokenString

    # Validate token
    try {
        $user = gh api user --jq '.login' 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Token validation failed"
        }
        Write-Verbose "Successfully authenticated as: $user"
        return $true
    }
    catch {
        Write-Error "Invalid GitHub token or authentication failed."
        Remove-Item Env:GH_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:GH_TOKEN_TEMP -ErrorAction SilentlyContinue
        return $false
    }
    finally {
        # Clear the token string from memory
        $tokenString = $null
    }
}

function Initialize-DestinationDirectory {
    <#
    .SYNOPSIS
    Validates and creates the destination directory if needed.
    #>
    param(
        [string]$Path
    )

    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if (-not $resolvedPath) {
            Write-Host "Creating destination directory: $Path" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            $resolvedPath = Resolve-Path -Path $Path
        }

        if (-not (Test-Path -Path $resolvedPath -PathType Container)) {
            Write-Error "Destination path exists but is not a directory: $Path"
            return $false
        }

        Write-Verbose "Using destination directory: $resolvedPath"
        return $true
    }
    catch {
        Write-Error "Failed to create or access destination directory '$Path': $($_.Exception.Message)"
        return $false
    }
}

function Get-UserRepositories {
    <#
    .SYNOPSIS
    Retrieves repositories for a user based on visibility and fork preferences.
    #>
    param(
        [string]$Username,
        [string]$Visibility,
        [bool]$IncludeForks
    )

    $allRepositories = @()

    try {
        # Get private repositories (original logic - always includes forks for private repos)
        if ($Visibility -eq "private" -or $Visibility -eq "both") {
            Write-Host "Fetching private repositories..." -ForegroundColor Cyan
            $privateRepos = gh repo list $Username --visibility=private --limit 1000 --json 'name,url,isFork' 2>$null

            if ($LASTEXITCODE -eq 0 -and $privateRepos) {
                $privateReposArray = $privateRepos | ConvertFrom-Json
                if ($privateReposArray) {
                    $allRepositories += $privateReposArray
                    Write-Host "Found $($privateReposArray.Count) private repositories" -ForegroundColor Green
                }
            }
        }

        # Get public repositories (original logic with jq filtering for forks)
        if ($Visibility -eq "public" -or $Visibility -eq "both") {
            if ($IncludeForks) {
                Write-Host "Fetching public repositories (including forks)..." -ForegroundColor Cyan
                $publicRepos = gh repo list $Username --visibility=public --limit 1000 --json 'name,url,isFork' 2>$null
                if ($LASTEXITCODE -eq 0 -and $publicRepos) {
                    $publicReposArray = $publicRepos | ConvertFrom-Json
                    if ($publicReposArray) {
                        $allRepositories += $publicReposArray
                        Write-Host "Found $($publicReposArray.Count) public repositories (including forks)" -ForegroundColor Green
                    }
                }
            }
            else {
                Write-Host "Fetching public repositories (excluding forks)..." -ForegroundColor Cyan
                # Use original jq filtering approach for excluding forks
                $publicRepos = gh repo list $Username --visibility=public --limit 1000 --json 'name,url,isFork' --jq '.[] | select(.isFork == false)' 2>$null
                if ($LASTEXITCODE -eq 0 -and $publicRepos) {
                    # Convert the individual JSON objects to an array (original approach)
                    $publicReposArray = ($publicRepos -split "`n" | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_ | ConvertFrom-Json })
                    if ($publicReposArray) {
                        $allRepositories += $publicReposArray
                        Write-Host "Found $($publicReposArray.Count) public repositories (excluding forks)" -ForegroundColor Green
                    }
                }
            }
        }

        return $allRepositories
    }
    catch {
        Write-Error "Failed to retrieve repositories: $($_.Exception.Message)"
        return @()
    }
}

function Invoke-RepositoryCloning {
    <#
    .SYNOPSIS
    Clones repositories with progress reporting and error handling.
    #>
    param(
        [array]$Repositories,
        [string]$DestinationPath
    )

    $results = @()
    $total = $Repositories.Count
    $current = 0

    # Change to destination directory
    try {
        Set-Location -Path $DestinationPath
    }
    catch {
        Write-Error "Failed to change to destination directory: $($_.Exception.Message)"
        return $results
    }

    foreach ($repo in $Repositories) {
        $current++
        $percentComplete = [math]::Round(($current / $total) * 100)

        Write-Progress -Activity "Cloning GitHub Repositories" -Status "Processing $($repo.name) ($current of $total)" -PercentComplete $percentComplete

        $result = [PSCustomObject]@{
            Name = $repo.name
            Url = $repo.url
            IsFork = $repo.isFork
            Language = $repo.language
            Description = $repo.description
            Status = "Unknown"
            Message = ""
            Path = ""
        }

        try {
            $repoPath = Join-Path $DestinationPath $repo.name

            # Check if repository already exists
            if (Test-Path -Path $repoPath) {
                Write-Warning "Repository '$($repo.name)' already exists at '$repoPath'. Skipping..."
                $result.Status = "Skipped"
                $result.Message = "Repository already exists"
                $result.Path = $repoPath
            }
            else {
                Write-Host "Cloning $($repo.name)..." -ForegroundColor White
                $cloneOutput = gh repo clone $repo.url 2>&1

                if ($LASTEXITCODE -eq 0) {
                    $result.Status = "Success"
                    $result.Message = "Successfully cloned"
                    $result.Path = $repoPath
                    Write-Verbose "Successfully cloned $($repo.name)"
                }
                else {
                    $result.Status = "Failed"
                    $result.Message = $cloneOutput -join "`n"
                    Write-Error "Failed to clone $($repo.name): $($result.Message)"
                }
            }
        }
        catch {
            $result.Status = "Error"
            $result.Message = $_.Exception.Message
            Write-Error "Error cloning $($repo.name): $($_.Exception.Message)"
        }

        $results += $result
    }

    Write-Progress -Activity "Cloning GitHub Repositories" -Completed
    return $results
}

function Show-CloningSummary {
    <#
    .SYNOPSIS
    Displays a summary of the cloning operation results.
    #>
    param(
        [array]$Results
    )

    if (-not $Results -or $Results.Count -eq 0) {
        Write-Host "No results to display." -ForegroundColor Yellow
        return
    }

    $successful = $Results | Where-Object { $_.Status -eq "Success" }
    $failed = $Results | Where-Object { $_.Status -eq "Failed" -or $_.Status -eq "Error" }
    $skipped = $Results | Where-Object { $_.Status -eq "Skipped" }

    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "CLONING SUMMARY" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "Total repositories processed: $($Results.Count)" -ForegroundColor White
    Write-Host "Successfully cloned: $($successful.Count)" -ForegroundColor Green
    Write-Host "Skipped (already exist): $($skipped.Count)" -ForegroundColor Yellow
    Write-Host "Failed: $($failed.Count)" -ForegroundColor Red

    if ($failed.Count -gt 0) {
        Write-Host "`nFailed repositories:" -ForegroundColor Red
        $failed | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Message)" -ForegroundColor Red
        }
    }

    Write-Host "="*60 -ForegroundColor Cyan
}

#endregion

# If script is run directly (not dot-sourced), execute the function
if ($MyInvocation.InvocationName -ne '.') {
    # Convert script parameters to function parameters
    $params = @{}
    if ($Username) { $params.Username = $Username }
    if ($Visibility) { $params.Visibility = $Visibility }
    if ($DestinationPath) { $params.DestinationPath = $DestinationPath }
    if ($IncludeForks) { $params.IncludeForks = $IncludeForks }
    if ($Token) { $params.Token = $Token }

    Clone-Repos @params
}
