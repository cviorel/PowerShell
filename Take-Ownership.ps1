function Take-Ownership {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$Path
    )

    $exeFile = (Get-Command takeown.exe).Source
    $exeFile / D Y /R /F $Path
}



# TAKEOWN /D Y /R /F "C:\Windows\Temp\*"
# ICACLS "C:\Windows\Temp\*" /grant:r administrators:F /T /C /Q  2>&1
# ICACLS "D:\GitHub\" /reset /T /C /Q
