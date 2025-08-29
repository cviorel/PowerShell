$Global:SQLSERVER = "$env:COMPUTERNAME,10001"
$Global:DBNAME = "DBA"

Try {
    $SQLConnection = New-Object System.Data.SQLClient.SQLConnection
    $SQLConnection.ConnectionString = "server=$SQLSERVER;database=$DBNAME;Integrated Security=True;ApplicationIntent=ReadOnly"
    $SQLConnection.Open()
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to connect SQL Server:")
}

$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
$SQLCommand.CommandText = "SELECT @@SERVERNAME"
$SQLCommand.Connection = $SQLConnection

$SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SQLCommand
$SQLDataset = New-Object System.Data.DataSet
$SqlAdapter.fill($SQLDataset) | Out-Null

$tablevalue = @()
foreach ($data in $SQLDataset.tables[0]) {
    $tablevalue = $data[0]
    $tablevalue
}
$SQLConnection.close()
