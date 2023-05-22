
$printer = Get-Printer -Name "HP03970B*"
Get-PrintJob $printer | Remove-PrintJob

$printer.KeepPrintedJobs = $false
$printer.WorkOffline = $false
$printer.Put()

$printer = Get-WMIObject -Class win32_printer | ? { $_.name -like 'HP Color*' }
$printer.WorkOffline = $true
$printer.Put()


$status = $printer.PrinterStatus
$printer.Put()

Write-Host 'Pausing printers...'
gwmi win32_printer | % {$null = $_.pause()}

Write-Host 'Deleting jobs...'
gwmi win32_printjob | % {$null = $_.delete()}

Write-Host 'Resuming printers...'
gwmi win32_printer | % {$null = $_.resume()}

Write-Host 'Done!'