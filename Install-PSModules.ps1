Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

$modules = @(
    'dbatools',
    'Pester',
    'Plaster',
    'HtmlReport',
    'PSScriptAnalyzer',
    'posh-git',
    'PSWindowsUpdate',
    'ImportExcel',
    'DockerCompletion'
)

foreach ($module in $modules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Scope CurrentUser -Force -SkipPublisherCheck
    }
}
