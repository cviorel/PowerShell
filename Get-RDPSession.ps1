function Get-RDPSession {
<#
.SYNOPSIS
Returns disconnected and active RDP sessions for a server

.DESCRIPTION
Returns an object for each RDP sessions to a server using the qwinsta exe (Installed on a machine when you add the RSAT tools)

.PARAMETER ServerName
Name of the server you wish to gather information on

.NOTES
Requires qwinsta.exe on the machine that the function is run from

.EXAMPLE
Get-RDPSession -ServerName PRD-SQL-LG03

Returns any disconnected and active RDP sessiosn on PRD-SQL-LG03

.EXAMPLE
Get-RDPSession -ServerName PRD-SQL-LG03, PRD-SQL-LG02

Returns any disconnected and active RDP sessions on PRD-SQL-LG03 and PRD-SQL-LG02

.EXAMPLE
Get-DbaRegisteredServerName -SqlInstance prd-sql-int01 -Group '00 - All Environments' | Get-RDPSession

Gathers a list of SQL Servers from a CMS server then runs Get-RDPSession against each server
#>

    param ([parameter(ValueFromPipeline, Mandatory = $true)]
        [string[]]$ServerName
        )
    process {
        foreach ($server in $serverName) {
            Write-Verbose "Connecting to $server"
            try {
                $qwin = qwinsta /server:$server
                }
            catch {
                    write-output -message "Failed to return results from: $server"
                    continue
                }

            foreach ($row in $qwin){
                if ($row -match "Disc"){
                    #write-output $row
                    $out = $row.trim() -replace "\s+", ","
                    $split = $out.split(",")
                    [pscustomobject]@{
                        Server = $server;
                        Login = $split[0];
                        SessionType = $split[2];
                        Id = $split[1]
                    }

                }
                if ($row -match "Active"){
                    #write-output $row
                    $out = $row.trim() -replace "\s+", ","
                    $split = $out.split(",")
                    [pscustomobject]@{
                        Server = $server;
                        Login = $split[1];
                        SessionType = $split[3];
                        Id = $split[2]
                    }
                }
            }
        }
    }
}
