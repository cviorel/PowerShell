Set-Location 'C:\Program Files\Microsoft Corporation\RMLUtils'

$queries = @{
    Q_01 = "INSERT INTO [SQLStress].[dbo].[TestTable] VALUES (DEFAULT);"
    Q_02 = "SELECT 1"
    Q_03 = "SELECT TOP 10 * FROM [SQLStress].[dbo].[TestTable]"
    Q_04 = "UPDATE TOP(20) [SQLStress].[dbo].[TestTable] SET C1 = 'AAA';"
    Q_05 = "UPDATE TOP(100) [SQLStress].[dbo].[TestTable] SET C1 = 'ABC';"
    Q_06 = "UPDATE TOP(2000) [SQLStress].[dbo].[TestTable] SET C2 = 'AABCD';"
    Q_07 = "UPDATE TOP(300) [SQLStress].[dbo].[TestTable] SET C3 = 'AABBBCD';"
    Q_08 = "SELECT TOP (400) [ID], [Description], [C1] FROM [SQLStress].[dbo].[TestTable] WHERE C1 LIKE 'AAA%'"
    Q_09 = "SELECT TOP (500) [ID], [Description], [C1] FROM [SQLStress].[dbo].[TestTable] WHERE C2 LIKE 'AAB%'"
    Q_10 = "SELECT TOP (600) [ID], [Description], [C1] FROM [SQLStress].[dbo].[TestTable] WHERE C2 LIKE 'AABCD%'"
}

while ($true) {
    $index = (1..10 | Get-Random)
    if ($index -lt 10) {
        $index = "Q_0" + $index
    }
    else {
        $index = "Q_" + $index
    }

    $randomQuery = $queries[$index]

    .\ostress.exe -S"192.168.1.81,10001" -E -Q"$randomQuery" -n10 -r20 -q -Usa -P'SecretPa$$word' -sSQLStress
}
