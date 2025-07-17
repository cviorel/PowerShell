<#
.SYNOPSIS
Sanitizes a SQL Server execution plan file by anonymizing database, schema, table, column, and index names.

.DESCRIPTION
This script reads a SQL Server execution plan (.sqlplan) file, anonymizes sensitive information such as database, schema, table, column, and index names, and writes the sanitized content to a new file. The script ensures consistent replacements using mapping hashtables.

.PARAMETER InputFileName
The path to the input .sqlplan file that needs to be sanitized. This parameter is mandatory and must not be null or empty. The file name must end with .sqlplan.

.EXAMPLE
.\Sanitize-SqlPlan.ps1 -InputFileName "C:\Plans\MyQuery.sqlplan"
This command sanitizes the specified SQL Server execution plan file and writes the output to a new file with "_Cleaned" appended to the original file name.

.NOTES
- The script uses XML parsing to process the .sqlplan file.
- The script replaces database, schema, table, column, and index names with generic placeholders.
- The output file is saved in the same directory as the input file with "_Cleaned" appended to the original file name.
- The script uses verbose output to provide detailed processing information.

Based on the original script by Jonathan Kehayias: https://www.sqlskills.com/blogs/jonathan/sanitizing-execution-plans-using-powershell/
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('\.sqlplan$')]
    [ValidateNotNullOrEmpty()]
    [string]$InputFileName
)

# Initialize mapping hashtables for consistent replacements
$databaseMappings = @{}
$schemaMappings = @{}
$tableMappings = @{}
$columnMappings = @{}
$indexMappings = @{}

try {
    Write-Verbose "Loading file: $InputFileName"
    $fileContent = [string]::Join([Environment]::NewLine, (Get-Content $InputFileName -ErrorAction Stop))

    $xmlDocument = New-Object 'System.Xml.XmlDocument'
    $xmlDocument.LoadXml($fileContent)

    # Setup namespace manager
    $namespaceManager = New-Object 'System.Xml.XmlNamespaceManager' $xmlDocument.NameTable
    $namespaceManager.AddNamespace("sm", "http://schemas.microsoft.com/sqlserver/2004/07/showplan")

    # Cache node selections
    Write-Verbose "Selecting XML nodes"
    $stmtNodes = $xmlDocument.SelectNodes("//sm:StmtSimple", $namespaceManager)
    $columnNodes = $xmlDocument.SelectNodes("//sm:ColumnReference", $namespaceManager)
    $objectNodes = $xmlDocument.SelectNodes("//sm:Object", $namespaceManager)

    # Strip statement text
    Write-Verbose "Sanitizing statement text"
    $stmtNodes | ForEach-Object {
        $_.StatementText = "--Statement text stripped by PlanSanitizer PowerShell Script"
    }

    # Process database names
    Write-Verbose "Processing database references"
    $columnNodes | Where-Object { $_.Database } | ForEach-Object {
        if (-not $databaseMappings.ContainsKey($_.Database)) {
            $databaseMappings[$_.Database] = "[Database_$($databaseMappings.Count + 1)]"
        }
        $_.Database = $databaseMappings[$_.Database]
    }

    # Process schema names
    Write-Verbose "Processing schema references"
    $columnNodes | Where-Object { $_.Schema -and $_.Schema -ne "[dbo]" } | ForEach-Object {
        if (-not $schemaMappings.ContainsKey($_.Schema)) {
            $schemaMappings[$_.Schema] = "[Schema_$($schemaMappings.Count + 1)]"
        }
        $_.Schema = $schemaMappings[$_.Schema]
    }

    # Process table names
    Write-Verbose "Processing table references"
    $columnNodes | Where-Object { $_.Table } | ForEach-Object {
        if (-not $tableMappings.ContainsKey($_.Table)) {
            $tableMappings[$_.Table] = "[Table_$($tableMappings.Count + 1)]"
        }
        $_.Table = $tableMappings[$_.Table]
    }

    # Process column names
    Write-Verbose "Processing column references"
    $columnNodes | Where-Object {
        $_.Column -and
        $_.Column -notmatch '^(Union|ConstExpr|Expr|Uniq|KeyCo)'
    } | ForEach-Object {
        if (-not $columnMappings.ContainsKey($_.Column)) {
            $columnMappings[$_.Column] = "[Column_$($columnMappings.Count + 1)]"
        }
        $_.Column = $columnMappings[$_.Column]
    }

    # Process index names
    Write-Verbose "Processing index references"
    $objectNodes | Where-Object { $_.Index } | ForEach-Object {
        if (-not $indexMappings.ContainsKey($_.Index)) {
            $indexMappings[$_.Index] = "[Index_$($indexMappings.Count + 1)]"
        }
        $_.Index = $indexMappings[$_.Index]
    }

    # Write output using StringBuilder
    Write-Verbose "Writing sanitized output"
    $outputFileName = $InputFileName.Replace(".sqlplan", "_Cleaned.sqlplan")
    $outputBuilder = New-Object System.Text.StringBuilder
    $outputBuilder.Append($xmlDocument.OuterXml) | Out-Null
    [System.IO.File]::WriteAllText($outputFileName, $outputBuilder.ToString())

    Write-Verbose "Processing complete: $outputFileName"

}
catch {
    Write-Error "Failed to process file: $_"
    exit 1
}
