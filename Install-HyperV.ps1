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
        try {
            New-VMSwitch -SwitchName $SwitchName -SwitchType Internal
            Write-Host "Created new VM switch: $SwitchName"
        }
        catch {
            Write-Warning "Failed to create VM switch: $($_.Exception.Message)"
            Write-Host "Attempting to remove existing switch and recreate..."
            try {
                Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue | Remove-VMSwitch -Force
                New-VMSwitch -SwitchName $SwitchName -SwitchType Internal
                Write-Host "Successfully recreated VM switch: $SwitchName"
            }
            catch {
                Write-Error "Failed to recreate VM switch: $($_.Exception.Message)"
                return
            }
        }
    } else {
        Write-Host "VM switch '$SwitchName' already exists."
    }

    # Get the network adapter, with retry logic
    $vSwitch = $null
    $retryCount = 0
    $maxRetries = 3

    do {
        Start-Sleep -Seconds 2
        $vSwitch = Get-NetAdapter -Name "vEthernet ($SwitchName)" -ErrorAction SilentlyContinue
        if (-not $vSwitch) {
            Write-Host "Waiting for network adapter to be available... (Attempt $($retryCount + 1)/$maxRetries)"
            $retryCount++
        }
    } while (-not $vSwitch -and $retryCount -lt $maxRetries)

    if (-not $vSwitch) {
        Write-Warning "Could not find network adapter 'vEthernet ($SwitchName)'. Checking available adapters..."
        $availableAdapters = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
        if ($availableAdapters) {
            $vSwitch = $availableAdapters[0]
            Write-Host "Found adapter: $($vSwitch.Name)"
        } else {
            Write-Error "No network adapter found for switch '$SwitchName'"
            return
        }
    }

    if ($vSwitch) {
        # Create the host interface for the Internal switch. This will be the default gateway used by your NAT'd VMs.
        $existingIP = Get-NetIPAddress -InterfaceIndex $vSwitch.ifIndex -IPAddress $SwitchIp -ErrorAction SilentlyContinue
        if (-not $existingIP) {
            try {
                New-NetIPAddress -IPAddress $SwitchIp -PrefixLength $PrefixLength -InterfaceIndex $vSwitch.ifIndex
                Write-Host "Assigned IP address $SwitchIp to switch interface"
            }
            catch {
                Write-Warning "Failed to assign IP address: $($_.Exception.Message)"
                # Check if IP already exists on this interface
                $allIPs = Get-NetIPAddress -InterfaceIndex $vSwitch.ifIndex -ErrorAction SilentlyContinue
                if ($allIPs | Where-Object { $_.IPAddress -eq $SwitchIp }) {
                    Write-Host "IP address $SwitchIp already assigned to interface"
                } else {
                    Write-Error "Could not assign IP address to interface"
                    return
                }
            }
        } else {
            Write-Host "IP address $SwitchIp already assigned to switch interface"
        }

        # Create NAT object
        if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) {
            try {
                New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix 192.168.10.0/24
                Write-Host "Created NAT object: $NatName"
            }
            catch {
                Write-Warning "Failed to create NAT object: $($_.Exception.Message)"
            }
        } else {
            Write-Host "NAT object '$NatName' already exists"
        }
    }

    # # Cleanup
    # Get-NetNat -Name $NatName | Remove-NetNat -Confirm:$false
    # Get-VMSwitch -Name $SwitchName | Remove-VMSwitch -Force
}
