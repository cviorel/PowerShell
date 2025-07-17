#Requires -RunAsAdministrator

@("Restricted", "AllSigned") | Where-Object { $_ -eq (Get-ExecutionPolicy).ToString() } | ForEach-Object {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Confirm:$false
}

if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
}

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install Module
$isInstalled = Get-Module PSWindowsUpdate -ListAvailable
if (!($isInstalled)) {
    Install-Module PSWindowsUpdate
}

# Import Module
if (-not (Get-Module PSWindowsUpdate)) {
    Import-Module PSWindowsUpdate
}

$logFolder = "C:\Temp\Install-Updates"

if (!(Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
}

# Install Updates
Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot | Out-File "${logFolder}\$(Get-Date -f yyyy-MM-dd)-WindowsUpdate.log" -Force

$timeZone = "Romance Standard Time"
Set-TimeZone $timezone

Rename-Computer -NewName "ThinkPad-X1" -Force

wevtutil el | ForEach-Object { Write-Host "Clearing $_"; wevtutil cl "$_" }
