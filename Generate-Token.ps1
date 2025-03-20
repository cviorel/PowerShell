<#
.SYNOPSIS
Generates a token for Subsonic or Navidrome using a password and a random salt.

.DESCRIPTION
This script generates a token for Subsonic or Navidrome by concatenating a provided password with a randomly generated salt and then computing the MD5 hash of the concatenated string.

.PARAMETER Password
The password to be used for generating the token.

.FUNCTION Get-RandomSalt
Generates a random salt consisting of 12 alphanumeric characters.

.FUNCTION Get-MD5Hash
Computes the MD5 hash of a given input string.

.EXAMPLE
PS> .\Generate-Token.ps1 -Password "MySecretPassword"
Password: MySecretPassword
Salt: A1B2C3D4E5F6
Token: 5f4dcc3b5aa765d61d8327deb882cf99

.NOTES
The generated token can be used for authentication with Subsonic or Navidrome.
#>
# Generate tokens for Subsonic or Navidrome https://www.subsonic.org/pages/api.jsp
param(
    [string]$Password
)

# Function to generate a random salt
function Get-RandomSalt {
    $salt = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    return $salt
}

# Function to compute MD5 hash
function Get-MD5Hash {
    param(
        [string]$InputString
    )
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hash = $md5.ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}

# Generate a random salt
$Salt = Get-RandomSalt

# Concatenate password and salt
$ConcatenatedString = "$Password$Salt"

# Compute MD5 hash
$Token = Get-MD5Hash -InputString $ConcatenatedString

# Output results
Write-Output "Password: $Password"
Write-Output "Salt: $Salt"
Write-Output "Token: $Token"
