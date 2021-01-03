# From https://technet.microsoft.com/en-us/library/ff730944.aspx
# This will open an internet explorer window that will display all installed windows font names in their corresponding font.
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$objFonts = New-Object System.Drawing.Text.InstalledFontCollection
$colFonts = $objFonts.Families

$objIE = New-Object -com "InternetExplorer.Application"
$objIE.Navigate("about:blank")
$objIE.ToolBar = 0
$objIE.StatusBar = 0
$objIE.Visible = $True

$objDoc = $objIE.Document.DocumentElement.LastChild

foreach ($objFont in $colFonts) {
    $strHTML = $strHTML + "<font size='5' face='" + $objFont.Name + "'>" + $objFont.Name + "</font><br>"
}

$objDoc.InnerHTML = $strHTML
