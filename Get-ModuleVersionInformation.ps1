Function Get-ModuleVersionInformation {

    [Cmdletbinding()]
    Param()

    # Startup
    $Start = Get-Date
    Write-Verbose 'Get-ModuleVersionInformation'
    Write-Verbose 'Started at: [$start]'

    # Get the modules on the local system
    $Modules = Get-Module -ListAvailable -Verbose:$False
    Write-Verbose ("{0} modules locally" -f $modules.count)

    # For each module, see if it exists on PSGallery
    # Create/emit an object for each module with the name,
    # and the version number of local and remote versions
    Foreach ($Module in $Modules) {
        Write-Verbose "Processing $($module.name)"
        $UpdateHt = [ordered] @{ }   # create the hash table
        $UpdateHt.Name = $Module.Name     # Add name
        $UpdateHt.Version = $Module.Version # And local version

        Try {
            # Find module, and add gallery version number to hash table
            $GalMod = Find-Module $Module.name -ErrorAction Stop
            $Updateht.GalVersion = $GalMod.Version
        }
        # here - find module could not find the module in the gallery
        Catch {
            # If module isn't in the gallery
            $Updateht.GalVersion = [System.Version]::new(0, 0)
        }

        # Now emit the object
        New-Object -TypeName PSObject -Property $UpdateHt

    } # End foreach

    $End = Get-Date
    Write-Verbose "Stopped at: [$End]"
    Write-Verbose "Took $(($End-$Start).TotalSeconds) seconds"

} # End Function
