$fileName = "$HOME\Downloads\query.sql"
$outputDir = "$HOME\Downloads"

$i = 0; Get-Content $fileName -ReadCount 2500 | ForEach-Object { $i++; $_ | Out-File $outputDir\OutputName_$i.txt -Encoding utf8 }
