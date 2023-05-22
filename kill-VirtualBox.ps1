$ErrorActionPreference = "SilentlyContinue"

$appName = "VirtualBox"

$PIDS = Get-Process | Where {$_.ProcessName -match "$appName"} | select -expand Id

foreach ($procID in $PIDS ) {
    Stop-Process $procID
}