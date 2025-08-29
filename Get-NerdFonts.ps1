# $Env:UserProfile\AppData\Local\Microsoft\Windows\Fonts

$downloadLocation = "$env:TEMP\Fonts"

if ( -not (Test-Path -Path $downloadLocation)) {
    New-Item -Path $downloadLocation -ItemType Directory
}

$fontNames = @(
    # "3270",
    'Agave',
    'AnonymousPro',
    # "Arimo",
    'AurulentSansMono',
    # "BigBlueTerminal",
    # "BitstreamVeraSansMono",
    'CascadiaCode',
    'CodeNewRoman',
    # "Cousine",
    # "DaddyTimeMono",
    # "DejaVuSansMono",
    # "DroidSansMono",
    # "FantasqueSansMono",
    'FiraCode',
    # "FiraMono",
    # "Go-Mono",
    # "Gohu",
    # "Hack",
    # "Hasklig",
    # "HeavyData",
    # "Hermit",
    # "iA-Writer",
    # "IBMPlexMono",
    'Inconsolata',
    # "InconsolataGo",
    # "InconsolataLGC",
    # "Iosevka",
    'IntelOneMono',
    'JetBrainsMono',
    'Lekton',
    # "LiberationMono",
    # "Lilex",
    'Meslo',
    # "Monofur",
    # "Monoid",
    # "Mononoki",
    # "MPlus",
    # "Noto",
    # "OpenDyslexic",
    # "Overpass",
    'ProFont',
    # "ProggyClean",
    'RobotoMono',
    # "ShareTechMono",
    'SourceCodePro',
    # "SpaceMono",
    'Terminus',
    # "Tinos",
    # "Ubuntu",
    # "UbuntuMono",
    'VictorMono'
)

$url = 'https://github.com/ryanoasis/nerd-fonts/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$version = $realTagUrl.split('/')[-1].Trim('v')

Write-Host ":: Latest version: $version"

$initialSetting = $ProgressPreference
if ($initialSetting -ne 'SilentlyContinue') {
    $ProgressPreference = 'SilentlyContinue'
}
foreach ($font in $fontNames) {
    $realDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/' + "${font}.zip"
    Write-Host ":: Downloading $realDownloadUrl"
    Invoke-WebRequest -Uri $realDownloadUrl -OutFile "$downloadLocation/$font.zip"
}

$ProgressPreference = $initialSetting

$files = Get-ChildItem -Path $downloadLocation -Filter '*.zip'

foreach ($file in $files) {
    Expand-Archive -Path $file.FullName -DestinationPath "$downloadLocation\$($file.BaseName)" -Force
}

$fontFiles = [Collections.Generic.List[System.IO.FileInfo]]::new()

Get-ChildItem $downloadLocation -Filter '*.ttf' -Recurse | ForEach-Object {
    $fontFiles.Add($_)
}

Get-ChildItem $downloadLocation -Filter '*.otf' -Recurse | ForEach-Object {
    $fontFiles.Add($_)
}

$fontFilesDeDup = $fontFiles | Group-Object -Property BaseName | ForEach-Object { $_.Group[0] }

New-Item -Path "$downloadLocation\all" -ItemType Directory -ErrorAction SilentlyContinue
foreach ($fontFile in $fontFilesDeDup) {
    Copy-Item $fontFile.FullName -Destination "$downloadLocation\all" -Force
}

Invoke-Item "$downloadLocation\all"

# $fonts = $null
# foreach ($fontFile in $fontFilesDeDup) {
# 	if (!$fonts) {
# 		$shellApp = New-Object -ComObject shell.application
# 		$fonts = $shellApp.NameSpace(0x14)
# 	}
# 	$fonts.CopyHere($fontFile.FullName)
# }
