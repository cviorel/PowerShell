function Format-MacAddress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$macAddress
    )

    # Function to validate MAC address
    function Validate-MacAddress {
        param (
            [string]$address
        )

        # Pattern to match a valid MAC address with or without colons/dashes
        $macPattern = '^([A-Fa-f0-9]{2}([-:]?)){5}[A-Fa-f0-9]{2}$'

        if ($address -match $macPattern) {
            return $true
        }
        else {
            return $false
        }
    }

    # Check if the provided MAC address is valid
    if (-not (Validate-MacAddress -address $macAddress)) {
        throw "Invalid MAC address. Please provide a valid MAC address in the format: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX or a 12-character string."
    }

    # Remove any characters that are not alphanumeric (like colons or dashes)
    $formattedMacAddress = $macAddress -replace '[^a-zA-Z0-9]', ''

    # Convert the MAC address to uppercase
    $formattedMacAddress = $formattedMacAddress.ToUpper()

    # Return the formatted MAC address
    return $formattedMacAddress
}

# ThinkPad-X1
$formatted = Format-MacAddress -macAddress "60:f2:62:3d:c4:08"
Write-Output $formatted

# Samsung Galaxy S22 Ultra
$formatted = Format-MacAddress -macAddress "fa:12:19:5c:2f:58"
Write-Output $formatted

$formatted = Format-MacAddress -macAddress "8c:53:e6:ec:fa:60"
