
$clusterCNO = "SQLClu"
$domain = "DOMAIN.LOCAL"
$OUDistinguishName = "OU=SQL Servers,OU=PRODUCTION Servers,OU=DOMAIN Servers,DC=DOMAIN,DC=LOCAL"

$clusterFQDN = "$clusterCNO.$domain"

New-ADComputer -Name $clusterCNO -DNSHostName $domain -Path $OUDistinguishName -Enabled $true
$objUser = New-Object System.Security.Principal.NTAccount("DOMAIN\SQLClu")
$objADAR = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($objUser, "GenericAll","Allow")
$adName = Get-ADComputer -Identity $clusterCNO

$targetObj = Get-ADObject -Identity $adName.DistinguishedName -Properties *
$ntSecurityObj = $targetObj.nTSecurityDescriptor
$ntSecurityObj.AddAccessRule($objADAR)
Set-ADObject $adName -Replace @{ntSecurityDescriptor = $ntSecurityObj}



$clusterCNOList = @("SQLClu", "SQLN1", "SQLN2", "SQLN3")
$domain = "DOMAIN.LOCAL"

foreach ($cluCNO in $clusterCNOList) {
    $clusterFQDN = "$cluCNO.$domain"
    $adName = Get-ADComputer -Identity $cluCNO
    $dn = $adName.DistinguishedName
    Set-ADComputer -Identity $dn -Add @{'msds-supportedencryptiontypes' = 28}
    Set-ADComputer -Identity $dn -ServicePrincipalName $Null # clear all SPNs
    Set-ADComputer -Identity $dn -ServicePrincipalName @{Add = "Host/$cluCNO", "Host/$clusterFQDN", "MSClusterVirtualServer/$cluCNO", "MSClusterVirtualServer/$clusterFQDN", "MSServerClusterMgmtAPI/$cluCNO", "MSServerClusterMgmtAPI/$clusterFQDN"}
}
