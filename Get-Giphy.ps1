function Get-Giphy {
    param (
        [string]$Query,

        [ValidateRange(1, 5)]
        [int]$Count = 1
    )

    if (-not $Query) {
        Write-Host "Missing: <query>"
        Write-Host "Usage: Get-Giphy <query> [-Count <number>]"
        Write-Host "Examples:"
        Write-Host "  Get-Giphy yay"
        Write-Host "  Get-Giphy why -Count 3"
        Write-Host "  Get-Giphy 'laugh cry' -Count 5 | Set-Clipboard"
        return
    }

    try {
        $Url = "https://giphy.com/search/$Query"
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing

        # Extract GIF URLs from the Images property
        $GifUrls = $Response.Images | ForEach-Object { $_.src }

        if ($GifUrls.Count -eq 0) {
            Write-Host "No GIFs found for query: $Query"
            return
        }

        # Select random GIF URLs up to the specified count
        $RandomGifUrls = $GifUrls | Get-Random -Count ([math]::Min($Count, $GifUrls.Count))
        $RandomGifUrls
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}
