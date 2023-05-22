$ErrorActionPreference = "SilentlyContinue"

$appName = "VBoxHeadless"

$PIDS = Get-Process | Where {$_.ProcessName -match "$appName"} -ErrorAction 'Ingnore' | select -expand Id

foreach ($procID in $PIDS ) {
    Stop-Process $procID
}