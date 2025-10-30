<#
.SYNOPSIS
Creates a per-user python3.exe alias that points to the newest locally installed Python.

.DESCRIPTION
- Warns if not running as Administrator (mklink may require elevation unless Developer Mode is enabled).
- Lists existing Python-related aliases in %LOCALAPPDATA%\Microsoft\WindowsApps.
- Disables Microsoft Store Python shims by renaming python.exe and python3.exe to python*_disabled.exe (idempotent).
- Detects the newest Python folder named Python<version> under %LOCALAPPDATA%\Programs\Python and verifies python.exe exists.
- Removes any existing python3.exe in WindowsApps and creates a symbolic link (python3.exe -> newest python.exe) via cmd mklink.
- Makes "python3" resolve to the most recent user-installed Python without modifying system-wide installs.

.REQUIREMENTS
- Windows 10/11 and PowerShell
- A user-scoped Python installed in %LOCALAPPDATA%\Programs\Python\Python<version>
- Permission to create symbolic links (Administrator or Developer Mode / SeCreateSymbolicLinkPrivilege)

.SIDE EFFECTS
- Renames Microsoft Store Python shims under %LOCALAPPDATA%\Microsoft\WindowsApps.
- Overwrites any existing python3.exe in the same directory.

.ERRORS
- Exits with code 1 if no Python installations are found or if python.exe is missing in the detected folder.
- mklink may fail due to insufficient privileges or path issues.

.EXAMPLE
PS> .\Set-PythonAlias.ps1
Existing Python aliases in WindowsApps:
...
Found newest Python version: Python311
Target path: C:\Users\<you>\AppData\Local\Programs\Python\Python311\python.exe

.AFTER RUNNING
- Open a new terminal; running `python3` should launch the resolved Python.
- If it fails, enable Developer Mode or run the script elevated and retry.

.NOTES
Scope: Per-user
Idempotent: Yes (safe to re-run)
Revert: Delete %LOCALAPPDATA%\Microsoft\WindowsApps\python3.exe and rename python*_disabled.exe back to their original names.

.LINK
Python on Windows (Launcher py.exe): https://docs.python.org/3/using/windows.html#launcher
Enable Developer Mode (symlinks without admin): https://learn.microsoft.com/windows/apps/get-started/enable-your-device-for-development
#>

# Check if running with administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host 'Warning: Running without administrator privileges. Installation may require elevation.' -ForegroundColor Yellow
}

# Display existing python aliases
Write-Host "`nExisting Python aliases in WindowsApps:" -ForegroundColor Cyan
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WindowsApps" | Where-Object { $_.Name -match "python" }

# Make Rename-Item operations idempotent
if (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe") {
    Rename-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe" "python_disabled.exe" -ErrorAction SilentlyContinue
}

if (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe") {
    Rename-Item "$env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe" "python3_disabled.exe" -ErrorAction SilentlyContinue
}

# Get the newest Python version programmatically
$pythonBasePath = "$env:LOCALAPPDATA\Programs\Python"
$pythonVersions = Get-ChildItem -Path $pythonBasePath -Directory | Where-Object { $_.Name -match "^Python\d+$" }

if ($pythonVersions.Count -eq 0) {
    Write-Error "No Python installations found in $pythonBasePath"
    exit 1
}

# Sort by version number (extract numeric part and sort as integers)
$newestVersion = $pythonVersions | Sort-Object {
    [int]($_.Name -replace "Python", "")
} | Select-Object -Last 1

$target = Join-Path $newestVersion.FullName "python.exe"

# Verify the python.exe exists
if (-not (Test-Path $target)) {
    Write-Error "Python executable not found at: $target"
    exit 1
}

Write-Host "Found newest Python version: $($newestVersion.Name)"
Write-Host "Target path: $target"
$alias = "$env:LOCALAPPDATA\Microsoft\WindowsApps\python3.exe"

# Make symbolic link creation idempotent
if (Test-Path $alias) {
    Remove-Item $alias -Force
}

cmd /c mklink "$alias" "$target"
