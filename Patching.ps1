$sqlserver = $env:COMPUTERNAME

$sessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$remoteSession = New-PSSession -ComputerName $sqlserver -UseSSL -SessionOption $sessionOptions

Copy-Item $HOME\Documents\CU11\SQLServer2016-KB4527378-x64.exe -ToSession $remoteSession -Destination C:\temp -Verbose

Remove-PSSession -Session $remoteSession

Set-Location C:\Temp
.\SQLServer2016-KB4527378-x64.exe /qs /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances

$servers = @(
    'node1',
    'node2',
    'node3'
)

$ports = 10001..10006
$result = @()
foreach ($server in $servers) {
    foreach ($port in $ports) {
        $result += Test-DbaBuild -SqlInstance "$server,$port" -MaxBehind 1CU
    }
}
$result | Format-Table -AutoSize
