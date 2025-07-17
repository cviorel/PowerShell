# Requires -RunAsAdministrator

# Define the list of packages to install
$packages = @(
    "Bitwarden.Bitwarden",
    "Git.Git",
    "Google.Chrome",
    "JanDeDobbeleer.OhMyPosh",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Mozilla.Firefox",
    "Notepad++.Notepad++",
    "OBSProject.OBSStudio",
    "Python.Python.3.12",
    "StandardNotes.StandardNotes",
    "VideoLAN.VLC",
    "Adobe.Acrobat.Reader.64-bit",
    "dotPDN.PaintDotNet"
    # Uncomment the lines below to include additional packages
    # "7zip.7zip",
    # "AutoHotkey.AutoHotkey",
    # "Microsoft.SQLServerManagementStudio",
    # "Microsoft.Teams",
    # "Microsoft.WindowsTerminal",
    # "SlackTechnologies.Slack",
    # "XnSoft.XnViewMP",
    # "Zoom.Zoom"
)

# Iterate over each package in the list
foreach ($package in $packages) {
    try {
        # Attempt to install the package using winget
        Write-Host "Installing package: $package"
        winget install -e --id=$package -h
        Write-Host "Successfully installed package: $package"
    }
    catch {
        # If installation fails, output the error message
        Write-Host "Failed to install package: $package" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
