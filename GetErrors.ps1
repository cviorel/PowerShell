$Servers = Get-Content servers.txt

ForEach ($Server in $Servers) {
    Get-DbaSqlLog -SqlInstance $Server -LogNumber 0 | Where-Object { ( $_.text -like '*Error*' `
                -or $_.text -like "*Fail*"`
                -or $_.text -like "*dump*"`
                -or $_.text -like '*IO requests taking longer*'`
                -or $_.text -like '*is full*' `
        ) -and ($_.text -notlike '*found 0 errors*')`
            -and ($_.text -notlike '*without errors*')`
            -and $_.logdate -ge ((Get-Date).AddHours(-48))
    } | Export-Csv report.csv -NoTypeInformation
}
