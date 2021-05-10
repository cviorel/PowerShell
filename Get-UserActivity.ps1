if (!(Get-Module dbatools)) {
    Import-Module dbatools -Force
}

$startDTM = Get-Date

$sqlInstances = @(
    'Node1',
    'Node2',
    'Node3'
)

$query = @'
SELECT @@servername AS InstanceName
	,[ID]
	,[LogDT]
	,[StartTime]
	,[SessionID]
	,[RequestStatus]
	,[HostName]
	,[LoginName]
	,[DatabaseName]
	,[Query]
	,[CPU_time]
	,[QueryPlan]
	,[WaitType]
	,[LastWaitType]
	,[BlockingSessionID]
	,[resource_description]
	,[WaitTime]
	,[transferred]
FROM [DBA].[dbo].[tblRequests]
WHERE LoginName NOT IN (
		'NT AUTHORITY\SYSTEM'
		)
	AND LogDT >= dateadd(DAY, datediff(day, 0, getdate() - 1), 0)
	AND LogDT < dateadd(DAY, datediff(day, 0, getdate()), 0)
'@


$destSqlInstance = 'MonitoringNode'

foreach ($instance in $sqlInstances) {
    Write-Output ":: $instance"
    $params = @{
        SqlInstance         = $instance
        Destination         = $destSqlInstance
        Database            = 'DBA'
        DestinationDatabase = 'DBA'
        Table               = '[dbo].[tblRequests]'
        DestinationTable    = '[dbo].[tblRequestsUsers]'
        BatchSize           = 10000
        Query               = $query
    }

    Copy-DbaDbTableData @params
}

$endDTM = Get-Date

$elapsedTime = $(($endDTM - $startDTM))
Write-Verbose "::: Total Duration: $($elapsedTime.Hours) hour(s), $($elapsedTime.Minutes) minute(s) and $($elapsedTime.Seconds) seconds" -Verbose
