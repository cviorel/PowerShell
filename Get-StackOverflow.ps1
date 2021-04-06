<#
.SYNOPSIS
    Download the attach the Stack Overflow Database

.DESCRIPTION
    Download the attach the Stack Overflow Database

    https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/

    Prerequisites:
        - dbatools and 7Zip4PowerShell PowerShell modules. If they are not present, they will be installed from the official PSGallery

.PARAMETER Size
    Choose the database size:
        Small: 10GB database as of 2010.
            Expands to a ~10GB database called StackOverflow2010 with data from the years 2008 to 2010.

        Medium: 50GB database as of 2013.
            Expands to a ~50GB database called StackOverflow2013 with data from 2008 to 2013.

.PARAMETER Path
    The location to download the 7z file

.PARAMETER SqlInstance
    The SqlInstance where the files will be attached

.PARAMETER SqlCredential
    Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

.PARAMETER DataPath
    The location for the DATA files. If ommited we will use the default path from the instance.

.PARAMETER LogPath
    The location for the LOG files. If ommited we will use the default path from the instance.

.NOTES
    Author: Viorel Ciucu
    Website: https://cviorel.com
    License: MIT https://opensource.org/licenses/MIT

.EXAMPLE
    Get-StackOverflow -Size Small -Path C:\Temp\StackOverflow -SqlInstance 'server\instance' -SqlCredential (Get-Credential sa)

    Download and attach the small StackOverflow database and restore it to 'server\instance' instance.
    User needs to provide the SA credential

.EXAMPLE
    Get-StackOverflow -Size Small -Path C:\Temp\StackOverflow -SqlInstance 'server\instance'

    Download and attach the small StackOverflow database and restore it to 'server\instance' instance.
    Windows Authentication is used to connect to the SQL instance.
#>
function Get-StackOverflow {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Small', 'Medium')]
        [string]$Size,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$SqlInstance,

        [Parameter(Mandatory = $false)]
        [PSCredential]$SqlCredential,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string]$DataPath,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string]$LogPath
    )

    Switch ($Size) {
        'Small' { $url = 'https://downloads.brentozar.com/StackOverflow2010.7z' }
        'Medium' { $url = 'https://downloads.brentozar.com/StackOverflow2013_201809117.7z' }
    }

    if ($LocalFile) {
        if (-not (Test-Path -Path $LocalFile)) {
            Write-Error "$LocalFile doesn't exist!"
            return
        }
        if (-not ($LocalFile.EndsWith('.7z'))) {
            Write-Error "$LocalFile should be a 7z file!"
            return
        }
    }

    if ($Path) {
        $Path = $Path.TrimEnd("\")
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        }
        $outFile = $url | Split-Path -Leaf
    }

    if (Test-Path -Path "$Path\$outFile") {
        $LocalFile = "$Path\$outFile"
        $outFile = $LocalFile
        Write-Output "Local copy already exist ($LocalFile). Let's use it!"
    }
    else {
        try {
            # Create SSL/TLS secure channel
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            try {
                $ProgressPreference = "SilentlyContinue"
                Invoke-WebRequest $url -OutFile "$Path\$outFile" -UseBasicParsing
            }
            catch {
                (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                Invoke-WebRequest $url -OutFile "$Path\$outFile" -UseBasicParsing
            }
        }
        catch {
            Write-Output "Download failed. Please download manually from $url."
            return
        }
    }

    #region Install Powershell modules
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
    if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        catch {
        }
    }

    $requiredModules = @('dbatools', '7Zip4PowerShell')
    $installedModules = (Get-Module -ListAvailable).Name

    $requiredModules | ForEach-Object {
        if ($installedModules -notcontains $_) {
            try {
                Install-Module -Name $_ -Scope CurrentUser -ErrorAction SilentlyContinue
            }
            catch {
                Write-Error "Could not install $_ module!"
                return
            }
        }
    }
    #endregion Install Powershell modules

    #region extract
    if (Test-Path -Path $outFile) {
        try {
            Expand-7Zip -ArchiveFileName "$outFile" -TargetPath $Path
        }
        catch {
            Write-Error "Could not extract $outFile! The file might be corrupted!"
            return
        }
    }
    else {
        Write-Error "Could not find $outFile!"
        return
    }
    #endregion extract

    #region check if database exists
    try {
        $defaultPath = Get-DbaDefaultPath -SqlInstance $SqlInstance
    }
    catch {
        Write-Error "Could not connect to $SqlInstance!"
        return
    }

    $dataLocation = $defaultPath.Data
    $logLocation = $defaultPath.Log

    if ($DataPath) {
        $dataLocation = $DataPath.TrimEnd("\")
    }

    if ($LogPath) {
        $logLocation = $LogPath.TrimEnd("\")
    }

    $dbName = [io.path]::GetFileNameWithoutExtension($outFile)

    $exists = Get-DbaDatabase -SqlInstance $SqlInstance -Database $dbName
    #endregion check if database exists

    #region Attach database
    if ($null -eq $exists) {
        $listData = '*.mdf', '*.ndf'
        $filesData = Get-ChildItem -Path $Path -File -Recurse -Include $listData
        $filesData | ForEach-Object { Move-Item -Path $_.FullName -Destination $dataLocation -Force }

        $listLog = '*.ldf'
        $filesLog = Get-ChildItem -Path $Path -File -Recurse -Include $ListLog
        $filesLog | ForEach-Object { Move-Item -Path $_.FullName -Destination $logLocation -Force }

        $fileStructure = New-Object System.Collections.Specialized.StringCollection
        $allFiles = @()
        $allFiles += Get-ChildItem -Path $dataLocation -File -Recurse -Include $listData
        $allFiles += Get-ChildItem -Path $logLocation -File -Recurse -Include $listLog

        $allFiles | ForEach-Object { $fileStructure.Add("$($_.FullName)") }

        $saLogin = (Get-DbaLogin -SqlInstance $SqlInstance -Type SQL | Where-Object { $_.sid -eq 1 }).Name

        try {
            $doIt = Attach-DbaDatabase -SqlInstance $SqlInstance -Database $dbName -FileStructure $fileStructure -DatabaseOwner $saLogin
            $doIt.AttachResult
        }
        catch {
            Write-Error "Could not attach the $dbName database!"
            return
        }
    }
    else {
        Write-Error "$dbName database already exists!"
        return
    }
    #endregion Attach database
}
