$n1Props = Get-DbaSpConfigure -SqlInstance node1
$n2Props = Get-DbaSpConfigure -SqlInstance node2

$propcompare = foreach ($prop in $n1Props) {
    [pscustomobject]@{
        Config         = $prop.DisplayName
        'node1' = $prop.RunningValue
        'node2' = $n2Props | Where-Object ConfigName -EQ $prop.ConfigName | Select-Object -ExpandProperty RunningValue
    }
}

$propcompare | Out-GridView
