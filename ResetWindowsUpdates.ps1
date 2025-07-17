#Gets computers you would like to reset windows update on based on OU
$Computers = Get-ADComputer -Filter * -SearchBase "DC=CONTOSO,DC=COM" | Select-Object DNSHostName -ExpandProperty DNSHostname

foreach ($Computer in $Computers) {
    $Computer
    Invoke-Command -ComputerName $Computer -ScriptBlock { Stop-Service "wuauserv" }
    Invoke-Command -ComputerName $Computer -ScriptBlock { Remove-Item C:\Windows\SoftwareDistribution -Force -Recurse }
    Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Service "wuauserv" }
}
