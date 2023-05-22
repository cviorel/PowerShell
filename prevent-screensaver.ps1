param($minutes = 120)
notepad.exe
$myShell = New-Object -com "Wscript.Shell"

for ($i = 0; $i -lt $minutes; $i++) {
    Start-Sleep -Seconds 30
    $myShell.sendkeys(".")
}