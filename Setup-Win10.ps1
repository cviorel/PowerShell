#Requires -RunAsAdministrator

@("Restricted", "AllSigned") | Where-Object { $_ -eq (Get-ExecutionPolicy).ToString() } | ForEach-Object {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force -Confirm:$false
}

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

$timeZone = "Romance Standard Time"
Set-TimeZone $timezone

Rename-Computer -NewName "ThinkPad-X1" -Force
