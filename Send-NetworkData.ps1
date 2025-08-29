<#
    .SYNOPSIS
        Sends a TCP stream

    .DESCRIPTION
        Sends a TCP stream

    .PARAMETER Computer
        The target host where the payload will be sent

    .PARAMETER Port
        The TCP port

    .PARAMETER Data
        Contains the payload

    .PARAMETER Encoding
        Encoding of the payload. Defaults to ASCII

    .PARAMETER Timeout
        Connection timeout. If not specified, the timeout is Infinite

    .EXAMPLE
        'this is a string' | Send-NetworkData -Computer $url -Port 2013

        Sends 'this is a string' payload to $url that is listening on port 2013

    .EXAMPLE
        'GET / HTTP/1.0', '' | Send-NetworkData -Computer www.google.com -Port 80

        Pipe in a HTTP request:

    .EXAMPLE
        Send-NetworkData -Data 'GET / HTTP/1.0', '' -Computer www.google.com -Port 80\

        Use the Data parameter to do the same

    .EXAMPLE
        Send-NetworkData -Data 'GET / HTTP/1.0', '' -Computer www.google.com -Port 80 -Timeout 0:00:02

        As before but only wait 2 seconds for a response

    .EXAMPLE
        Send-NetworkData -Data "EHLO $Env:ComputerName", "QUIT" -Computer mail.example.com -Port 25

        Say hello to an SMTP server

    .EXAMPLE

        $url = '192.168.1.100'
        $data = @'
metric_name_01 5 1603364196
metric_name_01 7 1603364196
metric_name_01 1 1603364196
metric_name_01 0 1603364196
'@
        $data | Send-NetworkData -Computer $url -Port 2013

        Sends $data payload to $url that is listening on port 2013

    .NOTES
        Author: Viorel Ciucu
        Github: https://github.com/cviorel
        License: MIT https://opensource.org/licenses/MIT

    .FUNCTIONALITY
#>
function Send-NetworkData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Computer,

        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [uint16]
        $Port,

        [Parameter(ValueFromPipeline)]
        [string[]]
        $Data,

        [System.Text.Encoding]
        $Encoding = [System.Text.Encoding]::ASCII,

        [TimeSpan]
        $Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    )

    begin {
        $Client = New-Object -TypeName System.Net.Sockets.TcpClient
        $Client.Connect($Computer, $Port)
        $Stream = $Client.GetStream()
        $Writer = New-Object -Type System.IO.StreamWriter -ArgumentList $Stream, $Encoding, $Client.SendBufferSize, $true
    }

    process {
        foreach ($Line in $Data) {
            $Writer.WriteLine($Line)
        }
    }

    end {
        $Writer.Flush()
        $Writer.Dispose()
        $Client.Client.Shutdown('Send')

        $Stream.ReadTimeout = [System.Threading.Timeout]::Infinite
        if ($Timeout -ne [System.Threading.Timeout]::InfiniteTimeSpan) {
            $Stream.ReadTimeout = $Timeout.TotalMilliseconds
        }

        $Result = ''
        $Buffer = New-Object -TypeName System.Byte[] -ArgumentList $Client.ReceiveBufferSize
        do {
            try {
                $ByteCount = $Stream.Read($Buffer, 0, $Buffer.Length)
            }
            catch [System.IO.IOException] {
                $ByteCount = 0
            }
            if ($ByteCount -gt 0) {
                $Result += $Encoding.GetString($Buffer, 0, $ByteCount)
            }
        } while ($Stream.DataAvailable -or $Client.Client.Connected)

        Write-Output $Result

        # cleanup
        $Stream.Dispose()
        $Client.Dispose()
    }
}
