#Requires -RunAsAdministrator

$badPolicy = $false
@("Restricted", "AllSigned") | Where-Object { $_ -eq (Get-ExecutionPolicy).ToString() } | ForEach-Object {
    Write-Host "Your current PowerShell Execution Policy is set to '$(Get-ExecutionPolicy)' and will prohibit boxstarter from operating properly."
    Write-Host "Please use Set-ExecutionPolicy to change the policy to RemoteSigned or Unrestricted."
    $badPolicy = $true
}
if ($badPolicy) { return }

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

$timeZone = "Romance Standard Time"
Set-TimeZone $timezone

Rename-Computer -NewName "ThinkPad-X1" -Force

wevtutil el | ForEach-Object { Write-Host "Clearing $_"; wevtutil cl "$_" }

# Write-Host "Uninstalling Default Microsoft Applications"
# Get-AppxPackage "Microsoft.3DBuilder" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.BingFinance" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.BingNews" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.BingSports" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.BingWeather" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Getstarted" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MicrosoftOfficeHub" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Office.OneNote" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.People" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.SkypeApp" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Windows.Photos" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsAlarms" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsCamera" | Remove-AppxPackage
# Get-AppxPackage "microsoft.windowscommunicationsapps" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsMaps" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsPhone" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsSoundRecorder" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.ZuneMusic" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.ZuneVideo" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.AppConnector" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.ConnectivityStore" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Office.Sway" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Messaging" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.CommsPhone" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MicrosoftStickyNotes" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.OneConnect" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.WindowsFeedbackHub" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MinecraftUWP" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MicrosoftPowerBIForWindows" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.NetworkSpeedTest" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.MSPaint" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.Microsoft3DViewer" | Remove-AppxPackage
# Get-AppxPackage "Microsoft.RemoteDesktop" | Remove-AppxPackage


# # Hide Taskbar Search icon / box
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0

# # Hide Taskbar People icon
# If (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
#     New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
# }
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0

# # Hide recently and frequently used item shortcuts in Explorer
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0

# Write-Host "Disabling Remote Assistance"
# Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0

# Write-Host "Disabling Autoplay"
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1

# Write-Host "Hiding Taskbar Search Box"
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0

# Write-Host "Disabling Bing Search in Start Menu"
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0
# If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
#     New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
# }
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Type DWord -Value 1

# Write-Host "Showing Task Manager Details"
# If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager")) {
#     New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Force | Out-Null
# }
# $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
# If (!($preferences)) {
#     $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
#     While (!($preferences)) {
#         Start-Sleep -m 250
#         $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
#     }
#     Stop-Process $taskmgr
# }
# $preferences.Preferences[28] = 0
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences


# Write-Host "Stopping and Disabling Diagnostics Tracking Service"
# Stop-Service "DiagTrack" -WarningAction SilentlyContinue
# Set-Service "DiagTrack" -StartupType Disabled


# function Is64Bit { [IntPtr]::Size -eq 8 }

# function Enable-Net40 {
#     if (Is64Bit) { $fx = "framework64" } else { $fx = "framework" }
#     if (!(Test-Path "$env:windir\Microsoft.Net\$fx\v4.0.30319")) {
#         Write-Host "Downloading .net 4.5..."
#         Get-HttpToFile "https://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotnetfx45_full_x86_x64.exe" "$env:temp\net45.exe"
#         Write-Host "Installing .net 4.5..."
#         $pinfo = New-Object System.Diagnostics.ProcessStartInfo
#         $pinfo.FileName = "$env:temp\net45.exe"
#         $pinfo.Verb = "runas"
#         $pinfo.Arguments = "/quiet /norestart /log $env:temp\net45.log"
#         $p = New-Object System.Diagnostics.Process
#         $p.StartInfo = $pinfo
#         $p.Start() | Out-Null
#         $p.WaitForExit()
#         $e = $p.ExitCode
#         if ($e -ne 0) {
#             Write-Host "Installer exited with $e"
#         }
#         return $e
#     }
#     return 0
# }





# Set-Location -Path "D:\GitHub\PowerShell"

# Invoke-WindowsDiskCleanup.ps1
# Set-PageFile.ps1
# Install-HyperV.ps1
# Install-WSL.ps1
# Install-PSModules.ps1
# . .\Add-ToPath.ps1

# . .\Set-PageFile.ps1
# Set-PageFile "C:\pagefile.sys"




# Write-Host "Installing Steam"
# choco install -y steam

# Write-Host "Installing Origin"
# choco install -y origin

# Write-Host "Installing uPlay"
# choco install -y uplay
