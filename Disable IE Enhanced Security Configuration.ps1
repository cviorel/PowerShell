function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Rundll32 iesetup.dll, IEHardenLMSettings, 1, True
    Rundll32 iesetup.dll, IEHardenUser, 1, True
    Rundll32 iesetup.dll, IEHardenAdmin, 1, True
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Output "IE Enhanced Security Configuration (ESC) has been disabled."
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Output "User Access Control (UAC) has been disabled."
}
function Disable-IESecurity {
    $Keypath = "HKCU:\Software\Microsoft\Internet Explorer\Main"
    Set-ItemProperty -Path $Keypath -Name "Isolation" -Value "PMIL"
    Write-Output "Disable Enhanced Protected Mode successfully, please restart Internet Explorer to take it effect! "
}
function Disable-ProtectedMode {
    $localMachine = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\0"
    Set-ItemProperty -Path $localMachine -Name "2500" -Value 3 -Force

    $intranet = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
    Set-ItemProperty -Path $intranet -Name "2500" -Value 3 -Force

    $trusted = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
    Set-ItemProperty -Path $trusted -Name "2500" -Value 3 -Force

    $internet = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
    Set-ItemProperty -Path $internet -Name "2500" -Value 3 -Force

    $restricted = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
    Set-ItemProperty -Path $restricted -Name "2500" -Value 3 -Force

    Write-Output "Disable protected mode of all zones"
}

function Add-FeatureBFCache {
    New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\Main\FeatureControl\" -Name FEATURE_BFCACHE -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BFCACHE" -Name "iexplore.exe" -Value 0 -Force
    Write-Output "Add FEATURE_BFCACHE to registry"
}

Disable-UserAccessControl
Disable-InternetExplorerESC
Disable-IESecurity
Disable-ProtectedMode
Add-FeatureBFCache
