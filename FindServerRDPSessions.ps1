
# Get today's date for the report
$today = Get-Date

# Setup email parameters
$subject = "ACTIVE SERVER SESSIONS REPORT - " + $today
$priority = "Normal"
$smtpServer = ""
$emailFrom = "noreply@local.lan"
$emailTo = "yourEmail@local.lan"

# Create a fresh variable to collect the results. You can use this to output as desired
$SessionList = "ACTIVE SERVER SESSIONS REPORT - " + $today + "`n`n"


$ServerList = ".\servers.txt" | Out-Null

if (!($ServerList)) {
    $Servers = @("127.0.0.1")
} else {
    $Servers = Get-Content $ServerList
}

$SessionList = @()
# Loop through the list to query each server for login sessions
ForEach ($ServerName in $Servers) {

    # When running interactively, uncomment the Write-Host line below to show which server is being queried
    # Write-Host "Querying $ServerName"

    # Run the qwinsta.exe and parse the output
    $queryResults = (qwinsta /server:$ServerName | foreach { (($_.trim() -replace "\s+", ","))} | ConvertFrom-Csv)

    # Pull the session information from each instance
    ForEach ($queryResult in $queryResults) {
        $RDPUser = $queryResult.USERNAME
        $sessionType = $queryResult.SESSIONNAME

        # We only want to display where a "person" is logged in. Otherwise unused sessions show up as USERNAME as a number
        If (($RDPUser -match "[a-z]") -and ($RDPUser -ne $NULL)) {
            # When running interactively, uncomment the Write-Host line below to show the output to screen
            # Write-Host $ServerName logged in by $RDPUser on $sessionType
            $SessionList += $ServerName + " logged in by " + $RDPUser + " on " + $sessionType
        }
    }
}
$SessionList


# Send the report email
if ($smtpServer -ne "" -or ($PSEmailServer)) {
    Try {
        Send-MailMessage -To $emailTo -Subject "$subject" -Body "$SessionList" -SmtpServer $smtpServer -From $emailFrom -Priority $priority
    } Catch {
        Write-Verbose "Failed to send email!"
        Break
    } Finally {
        $Time = Get-Date
    }
}

# When running interactively, uncomment the Write-Host line below to see the full list on screen
$SessionList