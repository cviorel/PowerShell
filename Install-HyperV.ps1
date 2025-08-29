#Requires -RunAsAdministrator

# https://thinkpowershell.com/powershell-set-up-hyper-v-lab/
# https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v
# https://techcommunity.microsoft.com/t5/virtualization/windows-nat-winnat-capabilities-and-limitations/ba-p/382303
# https://www.youtube.com/watch?v=PYamsYQSmFY

Write-Host "Checking for Hyper-V..."
$rebootRequired = $false
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State -ne 'Enabled') {
    Write-Host(" ...Installing Hyper-V.")
    $wslinst = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    if ($wslinst.RestartNeeded -eq $true) {
        $rebootRequired = $true
    }
}
else {
    Write-Host " ...Hyper-V already installed."
}

if ($rebootRequired) {
    Write-Host "A reboot is required to finish installing Hyper-V"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    $vhdLocation = "D:\Hyper-V"

    if ($vhdLocation.EndsWith('\')) {
        $vhdLocation = $vhdLocation.Substring(0, $vhdLocation.Length - 1)
    }

    if(-not (Test-Path -Path $vhdLocation)) {
        New-Item -ItemType Directory -Path $vhdLocation | Out-Null
    }

    $vmPath = "$vhdLocation\VMs"
    $vdPath = "$vhdLocation\VHDs"

    $vmPath, $vdPath | ForEach-Object {
        if (!(Test-Path -Path $_)) {
            $null = New-Item -Path $_ -ItemType Directory
        }
    }

    Set-VMHost -VirtualHardDiskPath $vdPath
    Set-VMHost -VirtualMachinePath $vmPath

    $SwitchName = "HYPER-V-NAT-Network"
    $NatName = "HYPER-V-NAT-Network"
    $SwitchIp = "192.168.10.1"
    $PrefixLength = 24

    # Create the Internal switch to use for NAT
    $isSwitchCreated = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if (-not ($isSwitchCreated)) {
        New-VMSwitch -SwitchName $SwitchName -SwitchType Internal
    }

    $vSwitch = Get-NetAdapter -Name "vEthernet ($SwitchName)"

    if ($vSwitch) {
        # Create the host interface for the Internal switch. This will be the default gateway used by your NAT'd VMs.
        New-NetIPAddress -IPAddress $SwitchIp -PrefixLength $PrefixLength -InterfaceIndex $vSwitch.ifIndex

        # Create NAT object
        if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) {
            New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix 192.168.10.0/24
        }
    }

    # # Cleanup
    # Get-NetNat -Name $NatName | Remove-NetNat -Confirm:$false
    # Get-VMSwitch -Name $SwitchName | Remove-VMSwitch -Force
}
