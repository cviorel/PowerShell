
$servers = @(
    'Node01',
    'Node02',
    'Node03'
)

$scriptBock = { $server = $env:COMPUTERNAME
    $MPIODisks = Get-WmiObject -Namespace "root\wmi" -Class mpio_disk_info -ComputerName "$Server"

    Write-Host "Host Name : " $Server

    foreach ($Disk in $MPIODisks) {
        $mpiodrives = $disk.DriveInfo

        foreach ($Drive in $mpiodrives) {
            Write-Host "Drive : " $Drive.Name
            Write-Host "NumberPaths : " $Drive.NumberPaths
        }
    } }
$sessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

foreach ($sqlserver in $servers) {
    $remoteSession = New-PSSession -ComputerName $sqlserver -UseSSL -SessionOption $sessionOptions
    Invoke-Command -Session $remoteSession -ScriptBlock $scriptBock
    $remoteSession | Remove-PSSession
}
