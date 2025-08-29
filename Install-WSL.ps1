#Requires -RunAsAdministrator

Write-Host "Checking for Windows Subsystem for Linux..."
$rebootRequired = $false

try {
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne 'Enabled') {
        Write-Host " ...Installing Windows Subsystem for Linux."
        $wslinst = Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Windows-Subsystem-Linux
        if ($wslinst.RestartNeeded -eq $true) {
            $rebootRequired = $true
        }
    } else {
        Write-Host " ...Windows Subsystem for Linux already installed."
    }

    Write-Host "Checking for Virtual Machine Platform..."
    if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne 'Enabled') {
        Write-Host " ...Installing Virtual Machine Platform."
        $vmpinst = Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName VirtualMachinePlatform
        if ($vmpinst.RestartNeeded -eq $true) {
            $rebootRequired = $true
        }
    } else {
        Write-Host " ...Virtual Machine Platform already installed."
    }

    if ($rebootRequired) {
        Write-Host "A reboot is required to finish installing WSL2"
        Write-Host "After reboot, run this script again to complete the installation."
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        # Check if WSL is already installed and working
        Write-Host "Checking if WSL is already configured..."
        $wslInstalled = $false

        try {
            $wslList = wsl --list --quiet 2>$null
            if ($LASTEXITCODE -eq 0 -and $wslList) {
                Write-Host " ...WSL is already installed with distributions:"
                wsl --list --verbose
                $wslInstalled = $true
            }
        }
        catch {
            Write-Host " ...WSL not yet configured."
        }

        if (-not $wslInstalled) {
            Write-Host " ...Installing default WSL distribution..."
            wsl --install --no-launch

            if ($LASTEXITCODE -eq 0) {
                Write-Host "WSL installed successfully."
            } else {
                Write-Warning "WSL installation may have encountered issues. Exit code: $LASTEXITCODE"
            }
        } else {
            Write-Host "WSL is already fully installed and configured."
        }
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

# sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y
# sudo apt-get install python3-pip -y

# wsl.exe --install kali-linux
