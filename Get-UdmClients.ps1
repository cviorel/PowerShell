function Get-UdmClients {
    <#
    .SYNOPSIS
    Retrieves and exports client information from a Unifi Dream Machine (UDM), including a formatted MAC address.

    .DESCRIPTION
    This function connects to a specified Unifi Dream Machine, retrieves client information, and exports it to a file in the specified format (CSV, JSON, or Table). It includes a formatted MAC address field with all non-alphanumeric characters removed.

    .PARAMETER UdmIp
    The IP address of the Unifi Dream Machine.

    .PARAMETER Credential
    The credentials used to authenticate with the UDM. Use Get-Credential to create this object.

    .PARAMETER OutputPath
    The file path where the exported client information will be saved.

    .PARAMETER OutputFormat
    The format of the exported file. Valid options are "CSV", "JSON", or "Table". Defaults to "CSV".

    .PARAMETER AllClients
    If specified, retrieves all clients, including inactive ones.

    .EXAMPLE
    $cred = Get-Credential
    Get-UdmClients -UdmIp "192.168.1.1" -Credential $cred -OutputPath "C:\udm_clients.csv"

    This example retrieves client information from the UDM at 192.168.1.1 and exports it to a CSV file.

    .EXAMPLE
    Get-UdmClients -UdmIp "192.168.1.1" -Credential (Get-Credential) -OutputPath "C:\udm_clients.json" -OutputFormat "JSON"

    This example retrieves client information and exports it to a JSON file, prompting for credentials.

    .NOTES
    This function requires PowerShell 6.0 or later due to the use of -SkipCertificateCheck.
    Use with caution as it bypasses SSL certificate validation.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$UdmIp,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("CSV", "JSON", "Table", "Markdown", "AlignedMarkdown")]
        [string]$OutputFormat = "CSV",

        [Parameter(Mandatory = $false)]
        [switch]$AllClients
    )

    # Function to get authentication cookies
    function Get-AuthCookies {
        param (
            [string]$Url,
            [PSCredential]$Credential
        )

        $body = @{
            username = $Credential.UserName
            password = $Credential.GetNetworkCredential().Password
        } | ConvertTo-Json

        $params = @{
            Uri                  = $Url
            Method               = 'Post'
            Body                 = $body
            ContentType          = 'application/json'
            SessionVariable      = 'webSession'
            SkipCertificateCheck = $true
            ErrorAction          = 'Stop'
        }

        try {
            $null = Invoke-RestMethod @params
            return $webSession
        }
        catch {
            throw "Authentication failed: $_"
        }
    }

    # Function to get client data
    function Get-ClientData {
        param (
            [string]$Url,
            [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
        )

        $params = @{
            Uri                  = $Url
            Method               = 'Get'
            WebSession           = $WebSession
            SkipCertificateCheck = $true
            ErrorAction          = 'Stop'
        }

        try {
            $response = Invoke-RestMethod @params
            return $response.data
        }
        catch {
            throw "Failed to retrieve client data: $_"
        }
    }

    # Function to export data
    function Export-ClientData {
        param (
            [array]$Data,
            [string]$Path,
            [string]$Format
        )

        try {
            $formattedData = $Data | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "mac_formatted" -Value ($_.mac -replace '[^a-zA-Z0-9]', '').ToUpper() -PassThru
            }

            switch ($Format) {
                "CSV" {
                    $formattedData | Select-Object mac, mac_formatted, ip, hostname, name, oui | Export-Csv -Path $Path -NoTypeInformation
                }
                "JSON" {
                    $formattedData | ConvertTo-Json | Out-File $Path
                }
                "Table" {
                    $formattedData | Select-Object mac, mac_formatted, ip, hostname, name, oui | Format-Table -AutoSize | Out-File $Path
                }
                "Markdown" {
                    $formattedData | Select-Object mac, mac_formatted, ip, hostname, name, oui | ConvertTo-MarkdownTable | Out-File $Path
                }
                "AlignedMarkdown" {
                    $formattedData | Select-Object mac, mac_formatted, ip, hostname, name, oui | ConvertTo-AlignedMarkdownTable | Out-File $Path
                }
            }
            Write-Host "Client data exported to $Path"
        }
        catch {
            throw "Failed to export data: $_"
        }
    }

    function ConvertTo-MarkdownTable {
        param (
            [Parameter(ValueFromPipeline = $true)]
            $InputObject
        )

        begin {
            $first = $true
            $output = @()
        }

        process {
            if ($first) {
                $headers = $InputObject.PSObject.Properties.Name -join ' | '
                $separator = ($InputObject.PSObject.Properties.Name | ForEach-Object { '-' * $_.Length }) -join ' | '
                $output += $headers
                $output += $separator
                $first = $false
            }
            $values = $InputObject.PSObject.Properties.Value -join ' | '
            $output += $values
        }

        end {
            $output -join "`n"
        }
    }

    function ConvertTo-AlignedMarkdownTable {
        param (
            [Parameter(ValueFromPipeline = $true)]
            $InputObject
        )

        begin {
            $objects = @()
            $columnWidths = @{}
        }

        process {
            $objects += $InputObject
            foreach ($property in $InputObject.PSObject.Properties) {
                $length = if ($null -ne $property.Value) { $property.Value.ToString().Length } else { 0 }
                $currentMax = if ($columnWidths.ContainsKey($property.Name)) { $columnWidths[$property.Name] } else { 0 }
                $columnWidths[$property.Name] = [Math]::Max([Math]::Max($currentMax, $property.Name.Length), $length)
            }
        }

        end {
            $headerRow = @()
            $separatorRow = @()
            foreach ($column in $objects[0].PSObject.Properties.Name) {
                $headerRow += $column.PadRight($columnWidths[$column])
                $separatorRow += '-' * $columnWidths[$column]
            }
            $output = @(
            ($headerRow -join ' | '),
            ($separatorRow -join ' | ')
            )

            foreach ($object in $objects) {
                $row = @()
                foreach ($column in $object.PSObject.Properties.Name) {
                    $value = if ($null -ne $object.$column) { $object.$column.ToString() } else { '' }
                    $row += $value.PadRight($columnWidths[$column])
                }
                $output += ($row -join ' | ')
            }

            $output -join "`n"
        }
    }

    # Main function execution
    try {
        $loginUrl = "https://$UdmIp/api/auth/login"
        $webSession = Get-AuthCookies -Url $loginUrl -Credential $Credential

        if ($AllClients) {
            $clientsUrl = "https://$UdmIp/proxy/network/api/s/default/rest/user"
        }
        else {
            $clientsUrl = "https://$UdmIp/proxy/network/api/s/default/stat/sta"
        }

        $clientsData = Get-ClientData -Url $clientsUrl -WebSession $webSession

        Export-ClientData -Data $clientsData -Path $OutputPath -Format $OutputFormat
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

$Credential = Get-Credential admin


