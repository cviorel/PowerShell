  <#
      .SYNOPSIS
      This powershell script converts computer data size unit of measure between one format
      and another. Optionally you can specify the precision and return only 2 (or any given
      number) of digits after the decimal.

      .DESCRIPTION
      Size conversion in PowerShell is pretty straight forward. If you have a number in
      bytes and want to convert it into MB, or GB, it is as simple as typing 12345/1GB, or
      12345/1MB in PowerShell prompt or script.

      The problem comes when you want to convert a value from something other than bytes to
      something else, and being able to properly handle either base 10 (KB, MB, GB, etc.),
      or base 2 (KiB, MiB, GiB, etc.) size notations correctly.

      Another issue is that you may want to be able to control the precision of the returned
      result (e.g. 0.95 instead of 0.957870483398438).

      This script easily handles conversion from any-to-any (e.g. Bits, Bytes, KB, KiB, MB,
      MiB, etc.) It also has the ability to specify the precision of digits you want to
      recieve as the output.

      International System of Units (SI) Binary and Standard
      http://physics.nist.gov/cuu/Units/binary.html
      https://en.wikipedia.org/wiki/Binary_prefix
      https://en.wikipedia.org/wiki/Names_of_large_numbers
      https://en.wikipedia.org/wiki/Nibble

      Name            Symbol Value                                                                                 Unit  SI Notation US English Word
      --------------- ------ ------------------------------------------------------------------------------------- ----- ----------- ----------------
      Bit             b      1 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . bit
      Nibble                 4 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . bits   2^2
      Bytes           B      8 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . bits   2^3
      KiloByte        KB     1 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^3        Thousand
      KibiByte        KiB    1 024 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^10
      MegaByte        MB     1 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^6        Million
      MebiByte        MiB    1 048 576 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^20
      GigaByte        GB     1 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^9        Billion
      GibiByte        GiB    1 073 741 824 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^30
      TeraByte        TB     1 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^12       Trillion
      TebiByte        TiB    1 099 511 627 776 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^40
      PetaByte        PB     1 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^15       Quadrillion
      PebiByte        PiB    1 125 899 906 842 624 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^50
      ExaByte         EB     1 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^18       Quintillion
      ExbiByte        EiB    1 152 921 504 606 846 976 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^60
      ZettaByte       ZB     1 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^21       Sextillion
      ZebiByte        ZiB    1 180 591 620 717 411 303 424 . . . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^70
      YottaByte       YB     1 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^24       Septillion
      YobiByte        YiB    1 208 925 819 614 629 174 706 176 . . . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^80
      Brontobyte*            1 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . . . Bytes 10^27       Octillion
                             1 237 940 039 285 380 274 899 124 224 . . . . . . . . . . . . . . . . . . . . . . . . Bytes  2^90
      Geopbyte*              1 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . . . Bytes 10^30       Nonillion
                             1 267 650 600 228 229 401 496 703 205 376 . . . . . . . . . . . . . . . . . . . . . . Bytes  2^100
                             1 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . . . Bytes 10^33       Decillion
                             1 298 074 214 633 706 907 132 624 082 305 024 . . . . . . . . . . . . . . . . . . . . Bytes  2^110
                             1 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . . . Bytes 10^36       Undecillion
                             1 329 227 995 784 915 872 903 807 060 280 344 576 . . . . . . . . . . . . . . . . . . Bytes  2^120
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . . . Bytes 10^39       Duodecillion
                             1 361 129 467 683 753 853 853 498 429 727 072 845 824 . . . . . . . . . . . . . . . . Bytes  2^130
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . . . Bytes 10^42       Tredecillion
                             1 393 796 574 908 163 946 345 982 392 040 522 594 123 776 . . . . . . . . . . . . . . Bytes  2^140
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . . . Bytes 10^45       Quattuordecillion
                             1 427 247 692 705 959 881 058 285 969 449 495 136 382 746 624 . . . . . . . . . . . . Bytes  2^150
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . . . Bytes 10^48       Quindecillion
                             1 461 501 637 330 902 918 203 684 832 716 283 019 655 932 542 976 . . . . . . . . . . Bytes  2^160
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . . . Bytes 10^51       Sexdecillion
                             1 496 577 676 626 844 588 240 573 268 701 473 812 127 674 924 007 424 . . . . . . . . Bytes  2^170
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . . . Bytes 10^54       Septendecillion
                             1 532 495 540 865 888 858 358 347 027 150 309 183 618 739 122 183 602 176 . . . . . . Bytes  2^180
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . . . Bytes 10^57       Octodecillion
                             1 569 275 433 846 670 190 958 947 355 801 916 604 025 588 861 116 008 628 224 . . . . Bytes  2^190
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 . . Bytes 10^60       Novemdecillion
                             1 606 938 044 258 990 275 541 962 092 341 162 602 522 202 993 782 792 835 301 376 . . Bytes  2^200
                             1 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 Bytes 10^63       Vigintillion
                             1 645 504 557 321 206 042 154 969 182 557 350 504 982 735 865 633 579 863 348 609 024 Bytes  2^210

      * Apparently proposed names by some group or person(s); however, they're not in keeping with the current binary prefixes,
        and they _have not_ been ratified as official labels.

      .PARAMETER From
      Specify the unit of data measurement for the source value.

      .PARAMETER To
      Specify the desired unit of data measurement. If no unit is provided then an attempt is made to
      select the most applicable destination size, in base 2 notation (e.g. MiB, GiB, TiB), based upon
      the number of bytes in the source value.

      .PARAMETER Value
      Specifies the data value as a decimal number to be converted.

      .PARAMETER Precision
      Optional value for specifing the amount of precision desired for the data value conversion. If no
      precision value is provided it defaults to 4.

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From KB -To GB -Value 1024
      value unit
      ----- ----
      0.001 GB

      Convert from Kilobyte (Base 10) to Gigabyte (Base 10).

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From GB -To GiB -Value 1024

      value    unit
      -------- ----
      953.6743 GiB

      Convert from Gigabyte (Base 10) to GibiByte (Base 2).

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From TB -To TiB -Value 1024 -Precision 2

      value  unit
      ------ ----
      931.32 TiB

      Convert from Terabyte (Base 10) to Tebibyte (Base 2) with only 2 digits after the decimal.

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From B -Value 1024

      value    unit
      -------- ----
             1 KiB

      Convert from Bytes (Base 2) to most applicably sized base 2 unit, in this case Kibibyte (KiB).

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From B -Value 1048577

      value    unit
      -------- ----
             1 MiB

      Convert from Bytes (Base 2) to MebiByte (Base 2) with default level of precision.

      .EXAMPLE
      Convert-DataSizeUnitOfMeasure -From B -Value 1048577 -Precision 6

      value    unit
      -------- ----
      1.000001  MiB

      Convert from Bytes (Base 2) to MebiByte (Base 2) with level of precision set to 6.


      .NOTES
      File Name	    : Convert-DataSizeUnitOfMeasure.ps1
      Version       : 2.1.0
      Author	      : Void
      Created Date  : December 9, 2016
      Modified Dates: May 17, 2019
                      March 6, 2019
                      November 3, 2019

      Design ideal originally inspired from a post by Techibee posted on July 7, 2014
      http://techibee.com/powershell/convert-from-any-to-any-bytes-kb-mb-gb-tb-using-powershell/2376

      SI standard notes: In SI the "K" symbol represents Kelvin, a unit of temperature. However, since at least the early 1980's
      "KB" represents KiloBytes, a unit of digital information, representing 10^3 (1,000) bytes of data.
      There are some who belive that "KB" should be written as "kB" in order to conform to the SI standard of the lower case "k"
      representation of kilo. For the purposes of this function we will keep with the historical usage of "K<x>" representing
      Kilo<something>, as well as maintaining consistency with the other binary symbols, instead of trying to redefine terms
      using some form of retroactive continuity in order to please some modern form of sensitivity.

      .LINK
      https://github.com/void-gh/pwsh-data-size-unit-measure/

      .OUTPUTS
      System.Object. Returns an object with two components. One the decmial value, the other the unit of measurement as a string.

  #>
  [cmdletbinding()]
  param(
    [Parameter(position=0,Mandatory=$true,HelpMessage='You must specify the starting unit of measure.')]
    [validateset('b','bit','Nibble','Kbit','Kilobit','Kibibit','Kibit','Mbit','MegaBit','Mebibit','Mibit','Gbit','Gigabit','Gibit','Gibibit','Tbit','Terabit','Tibit','Tebibit','Pbit','Petabit','Pibit','Pebibit','Ebit','Exabit','Eibit','Exbibit','Zbit','Zettabit','Zibit','Zebibit','Ybit','Yottabit','Yibit','Yobibit','B','Byte','KB','Kilobyte','KiB','Kibibyte','MB','Megabyte','MiB','Mebibyte','GB','Gigabyte','GiB','Gibibyte','TB','Terabyte','TiB','Tebibyte','PB','Petabyte','PiB','Pebibyte','EB','Exabyte','EiB','Exbibyte','ZB','Zettabyte','ZiB','Zebibyte','YB','Yottabyte','YiB','Yobibyte',IgnoreCase = $false)]
    [string]$From,
    [Parameter(position=1)]
    [validateset('b','bit','B','Nibble','Byte','KB','Kilobyte','KiB','Kibibyte','MB','Megabyte','MiB','Mebibyte','GB','Gigabyte','GiB','Gibibyte','TB','Terabyte','TiB','Tebibyte','PB','Petabyte','PiB','Pebibyte','EB','Exabyte','EiB','Exbibyte','ZB','Zettabyte','ZiB','Zebibyte','YB','Yottabyte','YiB','Yobibyte',IgnoreCase = $false)]
    [AllowNull()]
    [string]$To,
    [Parameter(position=2,Mandatory=$true,HelpMessage='Please provide a data size to convert')]
    [double]$Value,
    [Parameter(Position=3)]
    [int]$Precision = 4
  )

  # Convert the supplied value to Bytes
  switch -casesensitive ($From) {
    { $_ -in 'b','bit' }         {$value = $value/8 }
    { $_ -in 'Nibble'  }         {$value = $value/2 }
    { $_ -in 'B','Byte' }        {$value = $Value }
    { $_ -in 'Kbit','Kilobit' }  {$value = ($value/8) * [math]::pow(10,3) }
    { $_ -in 'Kibit','Kibibit' } {$value = ($value/8) * [math]::pow(2,10) }
    { $_ -in 'KB','Kilobyte' }   {$value = $Value * [math]::pow(10,3) }
    { $_ -in 'KiB','Kibibyte' }  {$value = $value * [math]::pow(2,10) }
    { $_ -in 'Mbit','Megabit' }  {$value = ($value/8) * [math]::pow(10,6) }
    { $_ -in 'Mibit','Mebibit' } {$value = ($value/8) * [math]::pow(2,20) }
    { $_ -in 'MB','Megabyte' }   {$value = $Value * [math]::pow(10,6) }
    { $_ -in 'MiB','Mebibyte' }  {$value = $value * [math]::pow(2,20) }
    { $_ -in 'Gbit','Gigabit' }  {$value = ($value/8) * [math]::pow(10,9) }
    { $_ -in 'Gibit','Gibibit' } {$value = ($value/8) * [math]::pow(2,30) }
    { $_ -in 'GB','Gigabyte' }   {$value = $Value * [math]::pow(10,9) }
    { $_ -in 'GiB','Gibibyte' }  {$value = $value * [math]::pow(2,30) }
    { $_ -in 'Tbit','Terabit' }  {$value = ($value/8) * [math]::pow(10,12) }
    { $_ -in 'Tibit','Tebibit' } {$value = ($value/8) * [math]::pow(2,40) }
    { $_ -in 'TB','Terabyte' }   {$value = $Value * [math]::pow(10,12) }
    { $_ -in 'TiB','Tebibyte' }  {$value = $value * [math]::pow(2,40) }
    { $_ -in 'Pbit','Petabit' }  {$value = ($value/8) * [math]::pow(10,15) }
    { $_ -in 'Pibit','Pebibit' } {$value = ($value/8) * [math]::pow(2,50) }
    { $_ -in 'PB','Petabyte' }   {$value = $value * [math]::pow(10,15) }
    { $_ -in 'PiB','Pebibyte' }  {$value = $value * [math]::pow(2,50) }
    { $_ -in 'Ebit','Exabit' }   {$value = ($value/8) * [math]::pow(10,18) }
    { $_ -in 'Eibit','Exbibit' } {$value = ($value/8) * [math]::pow(2,60) }
    { $_ -in 'EB','Exabyte' }    {$value = $value * [math]::pow(10,18) }
    { $_ -in 'EiB','Exbibyte' }  {$value = $value * [math]::pow(2,60) }
    { $_ -in 'Zbit','Zettabit' } {$value = ($value/8) * [math]::pow(10,21) }
    { $_ -in 'Zibit','Zebibit' } {$value = ($value/8) * [math]::pow(2,70) }
    { $_ -in 'ZB','Zettabyte' }  {$value = $value * [math]::pow(10,21) }
    { $_ -in 'ZiB','Zebibyte' }  {$value = $value * [math]::pow(2,70) }
    { $_ -in 'Ybit','Yottabit' } {$value = ($value/8) * [math]::pow(10,24) }
    { $_ -in 'Yibit','Yobibit' } {$value = ($value/8) * [math]::pow(2,80) }
    { $_ -in 'YB','Yottabyte' }  {$value = $value * [math]::pow(10,24) }
    { $_ -in 'YiB','Yobibyte' }  {$value = $value * [math]::pow(2,80) }
  }

  If ( [string]::IsNullOrWhiteSpace( $To ) )
  { # If no 'To' unit is provided we calcuate the most applicable base 2 unit of measure based upon the number of bytes we've calculated.
    Switch ($Value)
    {
      { $_ -ge 0 -and $_ -lt 1   } { $To = 'b'; break; }
      { $_ -lt [math]::pow(2,10) } { $To = 'B'; break; }
      { $_ -lt [math]::pow(2,20) } { $To = 'KiB'; break; }
      { $_ -lt [math]::pow(2,30) } { $To = 'MiB'; break; }
      { $_ -lt [math]::pow(2,40) } { $To = 'GiB'; break; }
      { $_ -lt [math]::pow(2,50) } { $To = 'TiB'; break; }
      { $_ -lt [math]::pow(2,60) } { $To = 'PiB'; break; }
      { $_ -lt [math]::pow(2,70) } { $To = 'EiB'; break; }
      { $_ -lt [math]::pow(2,80) } { $To = 'ZiB'; break; }
      { $_ -lt [math]::pow(2,90) } { $To = 'YiB'; break; }
      Default { $To = 'YiB'; break; }
    }
  }

  # Convert the number of Bytes to the desired output
  switch -casesensitive ($To) {
    { $_ -in 'b','bit' }         {$value = $value * 8}
    { $_ -in 'Nibble' }          {$value = $value * 2}
    { $_ -in 'B','Byte' }        {$value = $value }
    { $_ -in 'KB','Kilobyte' }   {$value = $Value/[math]::pow(10,3) }
    { $_ -in 'KiB','Kibibyte' }  {$value = $value/[math]::pow(2,10) }
    { $_ -in 'MB','Megabyte' }   {$value = $Value/[math]::pow(10,6) }
    { $_ -in 'MiB','Mebibyte' }  {$value = $Value/[math]::pow(2,20) }
    { $_ -in 'GB','Gigabyte' }   {$value = $Value/[math]::pow(10,9) }
    { $_ -in 'GiB','Gibibyte' }  {$value = $Value/[math]::pow(2,30) }
    { $_ -in 'TB','Terabyte' }   {$Value = $Value/[math]::pow(10,12) }
    { $_ -in 'TiB','Tebibyte' }  {$Value = $Value/[math]::pow(2,40) }
    { $_ -in 'PB','Petabyte' }   {$Value = $Value/[math]::pow(10,15) }
    { $_ -in 'PiB','Pebibyte' }  {$Value = $Value/[math]::pow(2,50) }
    { $_ -in 'EB','Exabyte' }    {$Value = $Value/[math]::pow(10,18) }
    { $_ -in 'EiB','Exbibyte' }  {$Value = $Value/[math]::pow(2,60) }
    { $_ -in 'ZB','Zettabyte' }  {$value = $value/[math]::pow(10,21) }
    { $_ -in 'ZiB','Zebibyte' }  {$value = $value/[math]::pow(2,70) }
    { $_ -in 'YB','Yottabyte' }  {$value = $value/[math]::pow(10,24) }
    { $_ -in 'YiB','Yobibyte' }  {$value = $value/[math]::pow(2,80) }
  }

  $Results = [pscustomobject]@{
    value=[Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)
    unit = $To
  }
  return $Results
