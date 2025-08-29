
function Convert-Influx2Graphite ()
{
    <#
        .SYNOPSIS
            Convert stdin from Influx2 fromat to Graphite.
        .LINK
            see Influx2 Format here:
              https://docs.influxdata.com/influxdb/v0.13/write_protocols/write_syntax/
            Graphite (or more correctly carbon protocol "pickle")
              https://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-pickle-protocol
    #>

    [cmdletbinding()]

    param(
         [Parameter(ValueFromPipeline)] $Lines,
         $Prefix = "app.esf.$(([System.Net.Dns]::GetHostByName('localhost').HostName).Replace('\.', '_'))."
    ) #FIXME set up params type

    begin {
#        $Hostname = ([System.Net.Dns]::GetHostByName('localhost').HostName).Replace('\.', '_')
        $UnixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
        $NowTimestamp = [int][double]::Parse([int]([DateTime]::UtcNow - $UnixEpochStart).TotalSeconds)

    }

    process  {
        foreach ($Line in $Lines.Split("`n")) {
            $Tags,$Fields,$Timestamp =$line.Replace("`n","").Replace("`r","").Split(" ")

            if (! $Timestamp)  { # set processing time if timestam omitted
                $Timestamp = $NowTimestamp
            }
            foreach ($Field in $Fields.Split(",")) {
                Write-Host ("$Prefix" + $Tags.Replace(',', '.').Replace('=', '.') + "." + $Field.Replace('=', ' ') + " " + $Timestamp)
            }
        }
    }
}

# FIXME: add a real unit test
# $Testlines=@"
# a_measurement value=12
# a_measurement value=12 1439587925
# a_measurement,foo=bar value=12
# a_measurement,foo=bar value=12 1439587925
# a_measurement,foo=bar,bat=baz value=12,otherval=21 1439587925
# "@

# PS C:\> echo $Testlines |  Convert-Influx2Graphite
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.value 12 1584445071
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.value 12 1439587925
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.foo.bar.value 12 1584445071
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.foo.bar.value 12 1439587925
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.foo.bar.bat.baz.value 12 1439587925
# app.esf.FRWS3936.usr.cviorel.com.a_measurement.foo.bar.bat.baz.otherval 21 1439587925
