##############################################################################
##
## Add-SqlServerStartupParameter
##
## by Eric Humphrey (http://www.erichumphrey.com/category/powershell/)
##
##############################################################################

<#

.SYNOPSIS

Adds an entry to the startup parameters list for all instances of SQL Server
on a computer

.EXAMPLE

PS >Add-SqlServerStartupParameter '-T3226'

#>

param(
    ## The parameter you wish to add
    [Parameter(Mandatory = $true)]
    $StartupParameter
)

$hklmRootNode = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"

$props = Get-ItemProperty "$hklmRootNode\Instance Names\SQL"
$instances = $props.psobject.properties | Where-Object { $_.Value -like 'MSSQL*' } | Select-Object Value

$instances | ForEach-Object {
    $inst = $_.Value;
    $regKey = "$hklmRootNode\$inst\MSSQLServer\Parameters"
    $props = Get-ItemProperty $regKey
    $params = $props.psobject.properties | Where-Object { $_.Name -like 'SQLArg*' } | Select-Object Name, Value
    #$params | ft -AutoSize
    $hasFlag = $false
    foreach ($param in $params) {
        if ($param.Value -eq $StartupParameter) {
            $hasFlag = $true
            break;
        }
    }
    if (-not $hasFlag) {
        "Adding $StartupParameter"
        $newRegProp = "SQLArg" + ($params.Count)
        Set-ItemProperty -Path $regKey -Name $newRegProp -Value $StartupParameter
    }
    else {
        "$StartupParameter already set"
    }
}
