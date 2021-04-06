<#
.SYNOPSIS
    Attach the Stack Overflow Database

.DESCRIPTION
    Attach the Stack Overflow Database

    https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/

    Prerequisites:
        - dbatools and 7Zip4PowerShell PowerShell modules. If they are not present, they will be installed from the official PSGallery

.PARAMETER Url
    The url for the 7z file. It can be:
        - local file:     'D:\Temp\StackOverflow2010.7z'
        - network share:  '\\SERVER\sharedFolder\StackOverflow2010.7z'
        - web location:   'https://downloads.yourdomain.local/StackOverflow2010.7z'

.PARAMETER Path
    The location to extract the 7z file

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
    Get-StackOverflow -Url C:\Temp\StackOverflow2010.7z -Path C:\Temp -SqlInstance 'server\instance' -SqlCredential (Get-Credential sa)

    Extract C:\Temp\StackOverflow2010.7z and attach the files to 'server\instance' instance.
    User needs to provide the SA credential.

.EXAMPLE
    Get-StackOverflow -Url "\\SERVER\sharedFolder\StackOverflow2010.7z" -Path C:\Temp -SqlInstance 'server\instance'

    Extract '\\SERVER\sharedFolder\StackOverflow2010.7z' and attach the files to 'server\instance' instance.
    Windows Authentication is used to connect to the SQL instance.

.EXAMPLE
    Get-StackOverflow -Url "https://downloads.yourdomain.local/StackOverflow2010.7z" -Path Q:\Temp -SqlInstance 'localhost,10001' -DataPath D:\MSSQL\Data -LogPath L:\MSSQL\Log

    Downloads StackOverflow2010.7z from the specified domain and save it to Q:\Temp.
    If the file already exists, the existing file will be used.
    Extract StackOverflow2010.7z to Q:\Temp, move the .mdf and .ndf files to 'D:\MSSQL\Data' and .ldf files to 'L:\MSSQL\Log'.
    Finally, the files are attached to 'localhost,10001' instance.
    Windows Authentication is used to connect to the SQL instance.
#>
function Get-StackOverflow {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

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

    $testUrl = $Url -as [System.URI]
    if ($null -ne $testUrl.AbsoluteURI) {
        if ($testUrl.Scheme -match 'http|https') {
            $LocalFile = $false
        }

        if ($testUrl.Scheme -eq 'file') {
            $LocalFile = $true
        }
    }

    $outFile = $Url | Split-Path -Leaf

    $Path = $Path.TrimEnd("\")
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    }

    if ($LocalFile -eq $false) {
        $localFileName = "$Path\$outFile"
        if (!(Test-Path -Path $localFileName)) {
            try {
                # Create SSL/TLS secure channel
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                try {
                    $ProgressPreference = "SilentlyContinue"
                    Invoke-WebRequest $Url -OutFile "$localFileName" -UseBasicParsing
                }
                catch {
                    (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                    Invoke-WebRequest $Url -OutFile "$localFileName" -UseBasicParsing
                }
            }
            catch {
                Write-Output "Download failed. Please download manually from $Url."
                return
            }
        }
    } else {
        $localFileName = $Url
        if (!(Test-Path -Path $localFileName)) {
            Write-Error "Could not find $localFileName!"
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
    try {
        Expand-7Zip -ArchiveFileName "$localFileName" -TargetPath $Path
    }
    catch {
        Write-Error "Could not extract "$localFileName"! The file might be corrupted!"
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
