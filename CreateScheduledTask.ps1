$powershellCmd = (Get-Command powershell.exe).Definition

$action = New-ScheduledTaskAction -Execute $powershellCmd -Argument '-NoProfile -Executionpolicy bypass -WindowStyle Hidden -file "C:\PowerShell\GetData.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 7am
$settings = New-ScheduledTaskSettingsSet -Compatibility WIN8

# -LogonType S4U = 'Run whether user is logged in or not'
$STPrincipal = New-ScheduledTaskPrincipal -UserID "DOMAIN\username" -RunLevel "Highest" -LogonType S4U
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "MyTask" -Description "MyDescription" -Principal $STPrincipal -Settings $settings