#Requires -RunAsAdministrator

Write-Host "Checking for Windows Subsystem for Linux..."
$rebootRequired = $false
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne 'Enabled') {
    Write-Host(" ...Installing Windows Subsystem for Linux.")
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

function Update-Kernel () {
    Write-Host " ...Downloading WSL2 Kernel Update."
    $kernelURI = 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi'
    $kernelUpdate = ((Get-Location).Path) + '\wsl_update_x64.msi'
    (New-Object System.Net.WebClient).DownloadFile($kernelURI, $kernelUpdate)
    Write-Host " ...Installing WSL2 Kernel Update."
    msiexec /i $kernelUpdate /qn
    Start-Sleep -Seconds 5
    Write-Host " ...Cleaning up Kernel Update installer."
    Remove-Item -Path $kernelUpdate
}

function Get-Kernel-Updated () {
    # Check for Kernel Update Package
    Write-Host "Checking for Windows Subsystem for Linux Update..."
    $uninstall64 = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Select-Object DisplayName, Publisher, DisplayVersion, InstallDate
    if ($uninstall64.DisplayName -contains 'Windows Subsystem for Linux Update') {
        return $true
    } else {
        return $false
    }
}

if ($rebootRequired) {
    Write-Host "A reboot is required to finish installing WSL2"
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    if (!(Get-Kernel-Updated)) {
        Write-Host " ...WSL kernel update not installed."
        Update-Kernel
    } else {
        Write-Host " ...WSL update already installed."
    }

    Write-Host "Setting WSL2 as the default..."
    wsl --set-default-version 2

    $wslPath = "C:\WSL"
    if (!(Test-Path -Path $wslPath)) {
        New-Item -Path $wslPath -ItemType Directory | Out-Null
    }

    $ProgressPreference = 'SilentlyContinue'
    # Download Ubuntu
    if (!(Test-Path -Path "$wslPath\Ubuntu.appx")) {
        Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile "$wslPath\Ubuntu.appx" -UseBasicParsing
        Add-AppxPackage -Path $wslPath/Ubuntu.appx
    }

    if (!(Test-Path -Path "$wslPath\Kali.appx")) {
        Invoke-WebRequest -Uri https://aka.ms/wsl-kali-linux-new -OutFile "$wslPath\Kali.appx" -UseBasicParsing
        Add-AppxPackage -Path $wslPath/Kali.appx
    }
}

# Start-Process ubuntu1804.exe
# Start-Process kali.exe

# Ubuntu1804 install --root
# Ubuntu1804 run apt update
# Ubuntu1804 run apt upgrade


# sudo wget --no-check-certificate https://archive.kali.org/archive-key.asc -O /etc/apt/trusted.gpg.d/kali-archive-key.asc

# sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y
# sudo apt-get install python3-pip -y
