<#
.SYNOPSIS
Performs search and replace operations on text files and source code files in a specified folder.

.DESCRIPTION
The Invoke-TextReplacement function searches for a specified pattern in text files and source code files within a given folder (including subfolders) and replaces it with a specified replacement string. If the content of a file is changed, a backup of the original file is created.

.PARAMETER FolderPath
Specifies the path to the folder where the search and replace operation will be performed.

.PARAMETER SearchPattern
Specifies the pattern to search for in the files. This can be a regular expression or a simple string.

.PARAMETER Replacement
Specifies the replacement string to use when replacing the search pattern.

.EXAMPLE
Invoke-TextReplacement -FolderPath "C:\Files" -SearchPattern "old" -Replacement "new"
Performs a search and replace operation in the "C:\Files" folder, replacing all occurrences of "old" with "new" in the files.

.EXAMPLE
Invoke-TextReplacement -FolderPath "C:\Scripts" -SearchPattern "Error" -Replacement "Warning"
Performs a search and replace operation in the "C:\Scripts" folder, replacing all occurrences of "Error" with "Warning" in the files.

.NOTES
This function supports text files and source code files with the following extensions: .txt, .ps1, .bat, .cmd, .sql, .sh.
#>
function Invoke-TextReplacement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $true)]
        [string]$SearchPattern,

        [Parameter(Mandatory = $true)]
        [string]$Replacement
    )

    # Get all text files and source code files in the folder (and subfolders, if needed)
    $files = Get-ChildItem -Path $FolderPath -Recurse -File -Include "*.txt", "*.ps1", "*.bat", "*.cmd", "*.sql", "*.sh"

    foreach ($file in $files) {
        # Read the file content
        $content = Get-Content -Path $file.FullName -Raw

        # Perform the search and replace
        $updatedContent = $content -replace $SearchPattern, $Replacement

        # If the content was changed, write it back to the file and create a backup
        if ($content -ne $updatedContent) {
            $backupPath = $file.FullName + "." + (Get-Date -Format "yyyyMMdd_HHmmss") + ".bak"
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            Set-Content -Path $file.FullName -Value $updatedContent -Force
            Write-Output ":: Updated $($file.FullName) and created a backup at $($backupPath)"
        }
    }

    Write-Output "Search and replace completed."
}
