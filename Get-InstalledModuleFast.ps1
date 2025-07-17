# https://gist.github.com/JustinGrote/4cebf646cabd39a435e796754dfa0de1

function Get-InstalledModuleFast {
	param(
		#Modules to filter for. Wildcards are supported.
		[string]$Name,
		#Path(s) to search for modules. Defaults to your PSModulePath paths
		[string[]]$ModulePath = ($env:PSModulePath -split [System.IO.Path]::PathSeparator),
		#Return all installed modules and not just the latest versions
		[switch]$All
	)

	$allModules = foreach ($pathItem in $ModulePath) {
		#Skip paths that don't exist
		if (-not (Test-Path $pathItem)) { continue }

		Get-ChildItem -Path $pathItem -Filter "*.psd1" -Recurse -ErrorAction SilentlyContinue
		| Foreach-Object {
			$manifestPath = $_
			$manifestName = (Split-Path -ea 0 $_ -Leaf) -replace "\.psd1$"
			if ($Name -and $ManifestName -notlike $Name) { return }
			$versionPath = Split-Path -ea 0 $_
			[Version]$versionRoot = ( $versionPath | Split-Path -ea 0 -Leaf) -as [Version]

			if (-not $versionRoot) {
				# Try for a non-versioned module by resetting the search
				$versionPath = $_
			}

			$moduleRootName = (Split-Path -ea 0 $versionPath | Split-Path -ea 0 -Leaf)
			if ($moduleRootName -ne $manifestName) {
				Write-Verbose "$manifestPath doesnt match a module folder, not a module manifest. skipping..."
				return
			}

			try {
				$fullInfo = Import-PowerShellDataFile -Path $_ -Ea Stop
			}
			catch {
				Write-Warning "Failed to import module manifest for $manifestPath. Skipping for now..."
				return
			}

			if (-not $fullInfo) { return }
			$manifestVersion = $fullInfo.ModuleVersion -as [Version]
			if (-not $manifestVersion) { Write-Warning "$manifestPath has an invalid or missing ModuleVersion in the manifest. You should fix this. Skipping for now..."; return }

			if ($versionRoot -and $versionRoot -ne $manifestVersion) { Write-Warning "$_ has a different version in the manifest ($manifestVersion) than the folder name ($versionRoot). You should fix this. Skipping for now..."; return }

			#Add prerelease info if present
			if ($fullInfo.PrivateData.PSData.Prerelease) {
				$manifestVersion = [Management.Automation.SemanticVersion]"$manifestVersion-$($fullInfo.PrivateData.PSData.Prerelease)"
			}

			[PSCustomObject][ordered]@{
				Name = $moduleRootName
				Version = $manifestVersion
				Path = $_.FullName
			}
		}
	}

	$modulesProcessed = @{}

	$allModules
	| Sort-Object -Property Name, @{Expression='Version';Descending=$true}
	| ForEach-Object {
		if ($All) {return $_}
		if (-not $modulesProcessed.($_.Name)) {
			$modulesProcessed.($_.Name) = $true
			return $_
		}
	}
}
