# Remove VM
$vmName = "WIN10"

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue

if ($vm) {
    # Stop VM
    if ($vm.State -ne 'Off') {
        Stop-VM $vm -Force
    }

    # Remove all checkpoints
    $checkpoints = Get-VMSnapshot -VMName $vm.Name
    if ($checkpoints) {
        Remove-VMSnapshot -VMName $vm.Name -Confirm:$false
    }

    # Remove all disks
    $vhdFiles = Get-VHD -VMId $vm.Id -ErrorAction SilentlyContinue
    if ($vhdFiles) {
        $vhdFiles | ForEach-Object Path | Remove-Item -Force
    }

    # Remove VM
    $vm | Remove-VM -Force
    # remove folders
    Remove-Item $vm.Path -Recurse -Force
}
