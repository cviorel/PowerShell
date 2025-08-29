$LAN = Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ConnectionState -eq 'Connected' -and $_.InterfaceAlias -notmatch 'Loopback*' }

if ($null -ne $LAN.InterfaceAlias) {
    $routes = Get-NetRoute -InterfaceAlias $LAN.InterfaceAlias | Where-Object –FilterScript { $_.NextHop -Ne "::" } | Where-Object –FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object –FilterScript { $_.DestinationPrefix -Ne "0.0.0.0/0" }

    $cmd = @()
    $routes | ForEach-Object {
        $cmd += "New-NetRoute -DestinationPrefix $($_.DestinationPrefix) -InterfaceAlias $($LAN.InterfaceAlias) -NextHop $($_.NextHop) -RouteMetric $($_.RouteMetric)"
    }

    $cmd
}
else {
    Write-Output "No connected interfaces found!"
}
