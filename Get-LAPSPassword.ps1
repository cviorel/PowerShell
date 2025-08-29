
Set-Location .\Documents\Inventory

$hostsFromADLocation = "$HOME\Documents\Inventory\Hosts_In_AD"

$allFiles = Get-ChildItem -Path $hostsFromADLocation

$allFiles | ForEach-Object {
    Get-Content
}

Import-Module ActiveDirectory
$myHost = $env:COMPUTERNAME
$Computer = Get-ADComputer -Filter { Name -eq $myHost } -Property *
($Computer.'ms-Mcs-AdmPwd')
