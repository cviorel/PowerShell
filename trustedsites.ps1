# https://stackoverflow.com/questions/51720030/ie-browser-powershell-script-to-add-site-to-trusted-sites-list-disable-protec


# 1. Add site to trusted sites

# Setting IExplorer settings
Write-Verbose "Now configuring IE"

# Navigate to the domains folder in the registry
Set-Location "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-Location ZoneMap\Domains

# Create a new folder with the website name
New-Item chocolatey.org/ -Force # website part without https
Set-Location chocolatey.org/
New-ItemProperty . -Name https -Value 2 -Type DWORD -Force

Write-Host "Site added Successfully"
Start-Sleep -Seconds 2

# 2. Disable IE protected mode

# Disabling protected mode and making level 0

# Zone 0 - My Computer
# Zone 1 - Local Intranet Zone
# Zone 2 - Trusted sites Zone
# Zone 3 - Internet Zone
# Zone 4 - Restricted Sites Zone

# '2500' is the value name representing 'Protected Mode' tick. 3 = Disabled, 0 = Enabled

# Disable protected mode for all zones
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" -Name 2500 -Value "3"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" -Name 2500 -Value "3"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" -Name 2500 -Value "3"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4" -Name 2500 -Value "3"

Write-Host "IE protection mode turned Off successfully"

# 3. Bring down security level for all zones

# Set Level 0 for low
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1" -Name 1A10 -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2" -Name 1A10 -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" -Name 1A10 -Value "0"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4" -Name 1A10 -Value "0"

Stop-Process -Name explorer
