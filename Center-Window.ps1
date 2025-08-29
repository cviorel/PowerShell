using namespace System.Windows.Forms

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms

# Define WinAPI types in a separate script block for clarity
$script:WinAPIDefinition = @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

# Initialize WinAPI type if not already defined
if (-not ("WinAPI" -as [type])) {
    Add-Type -TypeDefinition $script:WinAPIDefinition
}

function Get-OpenWindow {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    try {
        $processes = Get-Process | Where-Object { $_.MainWindowTitle -ne "" }
        return $processes | ForEach-Object {
            [PSCustomObject]@{
                Handle      = $_.MainWindowHandle
                Title       = $_.MainWindowTitle
                ProcessName = $_.ProcessName
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'GetOpenWindowsError',
                [System.Management.Automation.ErrorCategory]::OperationStopped,
                $null
            )
        )
    }
}

function Get-WindowMonitor {
    [CmdletBinding()]
    [OutputType([System.Windows.Forms.Screen])]
    param (
        [Parameter(Mandatory)]
        [WinAPI+RECT]$WindowRect
    )

    $windowCenterX = ($WindowRect.Left + $WindowRect.Right) / 2
    $windowCenterY = ($WindowRect.Top + $WindowRect.Bottom) / 2

    foreach ($monitor in [Screen]::AllScreens) {
        $workArea = $monitor.WorkingArea
        if ($windowCenterX -ge $workArea.Left -and
            $windowCenterX -le $workArea.Right -and
            $windowCenterY -ge $workArea.Top -and
            $windowCenterY -le $workArea.Bottom) {
            return $monitor
        }
    }

    return [Screen]::PrimaryScreen
}

function Set-WindowCenter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [IntPtr]$WindowHandle,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$Margin = 2
    )

    try {
        if ($WindowHandle -eq [IntPtr]::Zero) {
            throw [System.ArgumentException]::new("Invalid window handle provided.")
        }

        # Get current window dimensions
        $windowRect = New-Object WinAPI+RECT
        $null = [WinAPI]::GetWindowRect($WindowHandle, [ref]$windowRect)

        $width = $windowRect.Right - $windowRect.Left
        $height = $windowRect.Bottom - $windowRect.Top

        # Get target monitor
        $monitor = Get-WindowMonitor -WindowRect $windowRect
        $screen = $monitor.WorkingArea

        # Calculate new position
        $newPosition = @{
            X      = [math]::Round(($screen.Width - $width) / 2) + $screen.Left
            Y      = [math]::Round(($screen.Height - $height) / 2) + $screen.Top
            Width  = [math]::Min($width, $screen.Width - (2 * $Margin))
            Height = [math]::Min($height, $screen.Height - (2 * $Margin))
        }

        # Adjust for margins
        $newPosition.X = [math]::Max($screen.Left + $Margin,
            [math]::Min($newPosition.X, $screen.Right - $newPosition.Width - $Margin))
        $newPosition.Y = [math]::Max($screen.Top + $Margin,
            [math]::Min($newPosition.Y, $screen.Bottom - $newPosition.Height - $Margin))

        # Apply new position
        $success = [WinAPI]::MoveWindow(
            $WindowHandle,
            $newPosition.X,
            $newPosition.Y,
            $newPosition.Width,
            $newPosition.Height,
            $true
        )

        if (-not $success) {
            throw [System.Runtime.InteropServices.ExternalException]::new(
                "Failed to move window to new position."
            )
        }

        Write-Verbose "Window centered successfully with $Margin px margin"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $_.Exception,
                'SetWindowCenterError',
                [System.Management.Automation.ErrorCategory]::OperationStopped,
                $WindowHandle
            )
        )
    }
}

function Show-WindowSelector {
    [CmdletBinding()]
    param()

    try {
        $windows = Get-OpenWindow

        if (-not $windows) {
            Write-Warning "No open windows found."
            return
        }

        Write-Host "`nAvailable Windows:" -ForegroundColor Cyan
        $windows | ForEach-Object -Begin { $i = 1 } -Process {
            Write-Host "[$i] $($_.Title) ($($_.ProcessName))"
            $i++
        }

        do {
            $choice = Read-Host "`nEnter the number of the window to center (1-$($windows.Count))"

            if ([string]::IsNullOrWhiteSpace($choice)) {
                Write-Warning "No input provided. Please enter a number."
                continue
            }

            if (-not [int]::TryParse($choice, [ref]$null)) {
                Write-Warning "Please enter a valid number."
                continue
            }

            $index = [int]$choice - 1
            if ($index -lt 0 -or $index -ge $windows.Count) {
                Write-Warning "Please select a number between 1 and $($windows.Count)."
                continue
            }

            $selectedWindow = $windows[$index]
            Write-Host "Centering window: $($selectedWindow.Title)" -ForegroundColor Green
            Set-WindowCenter -WindowHandle $selectedWindow.Handle
            break
        } while ($true)
    }
    catch {
        Write-Error -Exception $_.Exception -Category OperationStopped
    }
}

# # Export functions if this is imported as a module
# Export-ModuleMember -Function Set-WindowCenter, Show-WindowSelector
