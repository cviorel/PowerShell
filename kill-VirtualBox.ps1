$ErrorActionPreference = "SilentlyContinue"

$appName = "VirtualBox"

$PIDS = Get-Process | Where-Object { $_.ProcessName -match "$appName" } | Select-Object -expand Id

foreach ($procID in $PIDS ) {
    Stop-Process $procID
}
