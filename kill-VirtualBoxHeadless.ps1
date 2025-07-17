$ErrorActionPreference = "SilentlyContinue"

$appName = "VBoxHeadless"

$PIDS = Get-Process | Where-Object { $_.ProcessName -match "$appName" } -ErrorAction 'Ingnore' | Select-Object -expand Id

foreach ($procID in $PIDS ) {
    Stop-Process $procID
}
