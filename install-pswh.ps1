$randomFileName = [System.IO.Path]::GetRandomFileName()
$tmpMsiPath = Microsoft.PowerShell.Management\Join-Path ([System.IO.Path]::GetTempPath()) "$randomFileName.msi"
Microsoft.PowerShell.Utility\Invoke-RestMethod -Uri https://github.com/PowerShell/PowerShell/releases/download/v6.2.4/PowerShell-6.2.4-win-x64.msi -OutFile $tmpMsiPath
try
{
    Microsoft.PowerShell.Management\Start-Process -Wait -Path $tmpMsiPath
}
finally
{
    Microsoft.PowerShell.Management\Remove-Item $tmpMsiPath
}
