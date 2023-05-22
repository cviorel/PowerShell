
$sqlInstances = @{
    node01 = @('10001, 10002, 10005')
    node02 = @('10001, 10002, 10005')
    node03 = @('10001, 10002, 10003, 10004, 10005')
    node04 = @('10003, 10004')
}

$connStr = @()
foreach ($key in $sqlInstances.keys) {
    ($sqlInstances[$key]).Split(',').Trim() | ForEach-Object {
        $connStr += "$key,$_"
    }
}

$query = '
ALTER EVENT SESSION [LRQ] ON SERVER WITH (STARTUP_STATE = OFF);
GO
'
foreach ($connection in $connStr) {
    $connection
    Get-DbaXESession -SqlInstance "$connection" -Session LRQ | Stop-DbaXESession
    Invoke-DbaQuery -SqlInstance "$connection" -Query $query
}

# check if the settings were applied sucessfully
$result = @()
foreach ($connection in $connStr) {
    $result += Get-DbaXESession -SqlInstance "$connection" -Session LRQ

}
$result | Select-Object SqlInstance, Name, AutoStart, Status | Format-Table -AutoSize

# Modify the SQL Server Agent Job # V.1
foreach ($connection in $connStr) {
    $job = Get-DbaAgentJob -SqlInstance "$connection" -Job 'DBA Restart Extended Events LRQ & Errors' | Export-DbaScript -Passthru
    $newJob = $job -replace 'ALTER EVENT SESSION LRQ ON SERVER STATE = STOP', '/*ALTER EVENT SESSION LRQ ON SERVER STATE = STOP*/' -replace 'ALTER EVENT SESSION LRQ ON SERVER STATE = START', '/*ALTER EVENT SESSION LRQ ON SERVER STATE = START*/'
    Get-DbaAgentJob -SqlInstance "$connection" -Job 'DBA Restart Extended Events LRQ & Errors' | Remove-DbaAgentJob
    Invoke-DbaQuery -SqlInstance "$connection" -Query "$($newJob)"
}

# Modify the SQL Server Agent Job # V.2
$newCommand = '
/*
ALTER EVENT SESSION LRQ ON SERVER STATE = STOP;
ALTER EVENT SESSION LRQ ON SERVER STATE = START;
*/
ALTER EVENT SESSION Errors ON SERVER STATE = STOP;
ALTER EVENT SESSION Errors ON SERVER STATE = START;
'

foreach ($connection in $connStr) {
    $jobs = Get-DbaAgentJob -SqlInstance "$connection" -Job 'DBA Restart Extended Events LRQ & Errors'
    foreach ($job in $Jobs.Where{ $_.Name -like '*LRQ*' }) {
        foreach ($Step in $Job.jobsteps.Where{ $_.Name -eq 'restart extended events' }) {
            $Step.Command = $newCommand
            $Step.Alter()
        }
    }
}
