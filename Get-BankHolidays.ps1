function Get-BankHolidays {
    param(
        [string]$Year,
        [string]$CountryCode
    )

    try {
        $url = "https://openholidaysapi.org/PublicHolidays?countryIsoCode=$CountryCode&languageIsoCode=EN&validFrom=$Year-01-01&validTo=$Year-12-31"
        $headers = @{
            'accept' = 'text/plain'
        }

        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

        if (-not $response) {
            throw "API call failed!"
        }

        $response
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
}
