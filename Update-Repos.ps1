function Update-Repos {
    param (
        $RootFolder
    )

    if (Test-Path -Path $RootFolder -PathType Container) {
        Get-ChildItem -Recurse -Depth 2 -Force -Path $RootFolder |
        Where-Object { $_.Mode -match "h" -and $_.FullName -like "*\.git" } |
        ForEach-Object {
            Set-Location $_.FullName
            Set-Location ../
            git pull
            Set-Location ../
        }

    }
    else {
        Write-Error "Cannot find $RootFolder!"
    }
}
