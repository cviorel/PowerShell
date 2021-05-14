function findStuff {
    param (
        $String
    )

    $String = [regex]::Escape($String)

    $myLocations = @(
        'C:\Temp',
        'C:\Users\Viorel\OneDrive\Documents\GitHub'
    )

    $excludes = @('.vscode', '.exe', '.dll', '.cs', '.xml', '.pdb', '.psproj', '.gitub')
    $results = @()
    foreach ($location in $myLocations) {
        $results += (Select-String -Pattern $String -Path (Get-ChildItem -Recurse -Path $location | Where-Object { ($_.PSIsContainer -eq $false) -and ($excludes -notcontains $_.Extension) })) -join "`r`n"
    }

    Write-Output $results

}
