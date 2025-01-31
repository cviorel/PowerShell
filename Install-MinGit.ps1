if (!(Get-Command git -ErrorAction SilentlyContinue)) {

  $gitDir = "$env:LOCALAPPDATA\CustomGit"
  if (Test-Path $gitDir) { Remove-Item -Path $gitDir -Recurse -Force }
  New-Item -Path $gitDir -ItemType Directory
  $gitLatestReleaseApi = (Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/git-for-windows/git/releases/latest).Content | ConvertFrom-Json
  $mingitObject = $gitLatestReleaseApi.assets `
  | Where-Object { $_.name -match "MinGit-[\d.]*?-64-bit.zip" } `
  | Select-Object browser_download_url

  Write-Host "Matching asset count: $((Measure-Object -InputObject $mingitObject).Count)"

  if ((Measure-Object -InputObject $mingitObject).Count -eq 1) {
    $mingitObject `
    | ForEach-Object { Invoke-WebRequest -Uri $_.browser_download_url -UseBasicParsing -OutFile "$gitDir\mingit.zip" }

    Write-Host "Installing latest release fetched from github api!"
  }
  else {
    Write-Host "There were more than one mingit assets found in the latest release!"
    Write-Host "Installing release 2.35.1.2 instead!"

    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.35.1.windows.2/MinGit-2.35.1.2-64-bit.zip" -UseBasicParsing -OutFile "$gitDir\mingit.zip"
  }

  Expand-Archive -Path "$gitDir\mingit.zip" -DestinationPath "$gitDir"
  Remove-Item -Path "$gitDir\mingit.zip" -Recurse -Force

  if (([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)) -notlike "*$gitDir*") {
    Write-Host "Updating PATH"
    [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$gitDir\cmd", [System.EnvironmentVariableTarget]::User)
  }
}

$gitDir = "C:\Tools\Git"
if (([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)) -notlike "*$gitDir*") {
  Write-Host "Updating PATH"
  [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$gitDir\cmd", [System.EnvironmentVariableTarget]::User)
}
