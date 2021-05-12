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

# Invoke-WindowsDiskCleanup.ps1
# Set-PageFile.ps1
# Install-HyperV.ps1
# Install-WSL.ps1
# Install-PSModules.ps1
# . .\Add-ToPath.ps1

# . .\Set-PageFile.ps1
# Set-PageFile "C:\pagefile.sys"




# Write-Host "Installing Steam"
# choco install -y steam-client

# Write-Host "Installing Origin"
# choco install -y origin

# Write-Host "Installing uPlay"
# choco install -y uplay
