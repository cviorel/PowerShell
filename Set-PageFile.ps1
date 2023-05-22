function Set-PageFile {
    <#
    .SYNOPSIS
        Sets Page File to custom size

    .DESCRIPTION
        Disables automatic management of the pagefile, then applies the given values for path and page file size.
        Defaults to C:\pagefile.sys with a 4 Gb pagefile.

    .PARAMETER Path
        The page file's fully qualified file name (such as C:\pagefile.sys)

    .PARAMETER InitialSize
        The page file's initial size [MB]

    .PARAMETER MaximumSize
        The page file's maximum size [MB]

    .EXAMPLE
        C:\PS> Set-PageFile "C:\pagefile.sys" 4096 6144
    #>

    PARAM(
        [string]$Path = "C:\pagefile.sys",
        [int]$InitialSize = 4096,
        [int]$MaximumSize = 4096
    )

    $ComputerSystem = $null
    $CurrentPageFile = $null
    $modify = $false

    # Disables automatically managed page file setting first
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    if ($ComputerSystem.AutomaticManagedPagefile) {
        $ComputerSystem.AutomaticManagedPagefile = $false
        $ComputerSystem.Put()
    }

    $CurrentPageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($CurrentPageFile.Name -eq $Path) {
        # Keeps the existing page file
        if ($CurrentPageFile.InitialSize -ne $InitialSize) {
            $CurrentPageFile.InitialSize = $InitialSize
            $modify = $true
        }
        if ($CurrentPageFile.MaximumSize -ne $MaximumSize) {
            $CurrentPageFile.MaximumSize = $MaximumSize
            $modify = $true
        }
        if ($modify) { $CurrentPageFile.Put() }
    } else {
        # Creates a new page file
        $CurrentPageFile.Delete()
        Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name = $Path; InitialSize = $InitialSize; MaximumSize = $MaximumSize}
    }
}