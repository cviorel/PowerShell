function Invoke-OneFetch {
    param (
    )

    $gitBin = (Get-Command git.exe).Source
    if ($null -eq $gitBin) {
        Write-Error "You need to have git in your path!"
    }

    $onefetchBin = (Get-Command onefetch.exe).Source
    if ($null -eq $onefetchBin) {
        Write-Error "You need to have onefetch in your path!"
    }

    #$currentRepo = Invoke-Expression "&$gitbin rev-parse --show-toplevel" | Out-Null
    if (Test-Path -Path .git) {
        $currentRepo = Invoke-Expression "& `"$gitBin`" rev-parse --show-toplevel" | Out-Null
    } else {
        Write-Error "Not a Git repo!"
        return
    }

    if ($lastRepo -eq $lastRepo) {
        Invoke-Expression "& `"$onefetchBin`""
        $lastRepo = $currentRepo
    }
}
