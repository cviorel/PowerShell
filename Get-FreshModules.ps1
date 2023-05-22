
$ProgressPreference = 'SilentlyContinue'
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$temp = ([System.IO.Path]::GetTempPath())

$toolsPath = "C:\Temp\iso"

if (!(Test-Path -Path $toolsPath)) {
    $null = New-Item -Path $toolsPath -Type Directory -ErrorAction SilentlyContinue
}

$modules = @(
    'dbatools',
    'dbachecks',
    'Pester',
    'HtmlReport',
    'PSScriptAnalyzer',
    'HtmlReport',
    'PSFramework',
    'SecretServer'
)

# Download Modules
$modules | ForEach-Object {
    Save-Module $_ -Path $toolsPath
}

# Download sp_whoisactive
$zipfile = Join-Path -Path $temp -ChildPath "spwhoisactive.zip"
$baseUrl = "https://github.com/amachanic/sp_whoisactive/archive"
$latest = (((Invoke-WebRequest -UseBasicParsing -Uri https://github.com/amachanic/sp_whoisactive/releases/latest).Links | Where-Object { $PSItem.href -match "zip" } | Select-Object href -First 1).href -split '/')[-1]
$url = $baseUrl + "/" + $latest
try {
    Invoke-WebRequest $url -OutFile $zipfile -ErrorAction Stop -UseBasicParsing
    Copy-Item -Path $zipfile -Destination $toolsPath
}
catch {
    Write-Error "Couldn't download sp_WhoisActive. Please download and install manually from $url."
}

# Download Ola Hallengren's maintenance solution
$url = "https://github.com/olahallengren/sql-server-maintenance-solution/archive/master.zip"
$zipfile = "$temp\ola-sql-server-maintenance-solution.zip"
if ($zipfile | Test-Path) {
    Remove-Item -Path $zipfile -ErrorAction SilentlyContinue
}
try {
    Invoke-WebRequest $url -OutFile $zipfile -ErrorAction Stop -UseBasicParsing
    Copy-Item -Path $zipfile -Destination $toolsPath
}
catch {
    Write-Error "Couldn't download Ola Hallengren's maintenance solution. Please download and install manually from $url."
}

# Download First Responder Kit
$url = "https://github.com/BrentOzarULTD/SQL-Server-First-Responder-Kit/archive/master.zip"
$zipfile = "$temp\SQL-Server-First-Responder-Kit.zip"
try {
    Invoke-WebRequest $url -OutFile $zipfile -ErrorAction Stop -UseBasicParsing
    Copy-Item -Path $zipfile -Destination $toolsPath
}
catch {
    Write-Error "Couldn't download First Responder Kit. Please download and install manually from $url."
}
