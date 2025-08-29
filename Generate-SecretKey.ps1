function Generate-SecretKey {
    Add-Type -AssemblyName 'System.Security.Cryptography'
    $secretBytes = New-Object System.Byte[] 64
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($secretBytes)
    return [System.Convert]::ToBase64String($secretBytes)
}

# # Example usage
# $secretKey = Generate-SecretKey
# Write-Output $secretKey
