Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name dbatools -Scope CurrentUser
Install-Module -Name Pester -Force -SkipPublisherCheck
Install-Module -Name Plaster -Scope CurrentUser
Install-Module -Name HtmlReport -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Install-Module -Name posh-git -Scope CurrentUser
Install-Module -Name oh-my-posh -Scope CurrentUser
Install-Module -Name PSWindowsUpdate -Scope CurrentUser
Install-Module -Name ImportExcel -Scope CurrentUser