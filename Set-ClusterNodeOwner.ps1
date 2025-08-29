Import-Module FailoverClusters

# remove the vote from this node
$node = "TF-WINGUI02"
(Get-ClusterNode $node).NodeWeight = 0
$cluster = (Get-ClusterNode $node).Cluster
$nodes = Get-ClusterNode -Cluster $cluster
$nodes | Format-Table -Property NodeName, State, NodeWeight

# list  cluster  resources posssible owners
Get-ClusterResource | Where-Object { $_.State -eq 'Online' } | Get-ClusterOwnerNode

# list  cluster  resources posssible owners
# !!!
# !!! the Availability Group resources will be managed by the Availability Group
# !!!

$agName = 'cluster-ag'
$validOwners = @('TF-WINCORE02', 'TF-WINCORE03')

Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'Network Name' } | Get-ClusterOwnerNode
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'IP Address' } | Get-ClusterOwnerNode
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'File Share Witness' } | Get-ClusterOwnerNode

# Set the possible owners to only the nodes in primary DCs
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'Network Name' } | Set-ClusterOwnerNode –Owners $validOwners
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'IP Address' } | Set-ClusterOwnerNode –Owners $validOwners
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -ne $agName) -and $_.ResourceType -eq 'File Share Witness' } | Set-ClusterOwnerNode –Owners $validOwners


# After the node was added to the AG, changes the ownership for the AG cluster IP Address and AG Network Name
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -eq $agName) -and $_.ResourceType -eq 'Network Name' } | Get-ClusterOwnerNode
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -eq $agName) -and $_.ResourceType -eq 'IP Address' } | Get-ClusterOwnerNode

Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -eq $agName) -and $_.ResourceType -eq 'Network Name' } | Set-ClusterOwnerNode –Owners $validOwners
Get-ClusterResource | Where-Object { ($_.State -eq 'Online' -and $_.OwnerGroup -eq $agName) -and $_.ResourceType -eq 'IP Address' } | Set-ClusterOwnerNode –Owners $validOwners
