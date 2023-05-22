
# Checks for admin privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$Folder = "C:\Temp"
$mediaCreationToolUrl = "http://go.microsoft.com/fwlink/?LinkId=691209"
$mediaCreationToolExe = "C:\Temp\MediaCreationTool.exe"
$webClient = New-Object System.Net.WebClient

If (!(Test-Path $Folder)) {
    New-Item -ItemType Directory -Force -Path $Folder
    Write-Output 'Temp folder created'
    Start-Sleep -Seconds .5
}

$webClient.DownloadFile($mediaCreationToolUrl, $mediaCreationToolExe)
(New-Object System.Net.WebClient).DownloadFile($mediaCreationToolUrl, $mediaCreationToolExe)
Write-Output ".....Media Creation Tool downloaded"
Start-Sleep -Seconds 2

# Path to media creation tool
Write-Output "___________________________________"
Write-Output ".....Starting media creation tool"
Start-Sleep -Seconds 2
Set-Location C:\Temp

# Opens Enteprise version of Windows 10 tool
.\MediaCreationTool.exe /Eula Accept /Retail /MediaArch x64 /MediaLangCode en-US /MediaEdition Enterprise
