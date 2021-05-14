function Add-ToPath {
    param(
        [string]$Directory
    )

    if ( !(Test-Path $Directory) ) {
        Write-Warning "$Directory directory was not found!"
        return
    }
    $PATH = [Environment]::GetEnvironmentVariable("PATH")

    if ($Directory.EndsWith('\')) {
        $Directory = $Directory.Substring(0, $Directory.Length - 1)
    }

    if ( $PATH -notlike "*" + $Directory + "*" ) {
        [Environment]::SetEnvironmentVariable("PATH", "$PATH;$Directory", "Machine")
    }
}
