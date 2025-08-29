
$vmName = "WIN2012R2"

$vmState = Get-VM -Name $vmName

if ($vmState.State -ne 'Running') {
    Start-VM -Name $vmName
    Start-Sleep -Seconds 10
}

$vmNet = Get-VMNetworkAdapter -VMName $vmName
$ipv4 = $vmNet.IPAddresses | Select-Object -First 1

mstsc.exe /v:$ipv4