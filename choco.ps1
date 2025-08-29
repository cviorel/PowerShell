if (!(Test-Path $PROFILE)) {
    New-Item $PROFILE -ItemType File -Force
}

# Install Chocolatey
if (!(Get-Package -Name *choco*)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}


$githubs = @(
    "https://github.com/cviorel/dotfiles.git"
)

choco install firefox -y --force
choco install googlechrome -y --force
choco install 7zip -y --force
choco install notepadplusplus -y --force
choco install git -y --force --params "/NoShellIntegration /SChannel /NoGuiHereIntegration /NoShellHereIntegration"
choco install github-desktop -y --force
choco install vscode -y --force
choco install vscode-powershell -y --force
choco install vlc -y --force
choco install sysinternals -y --force --params "/InstallDir:C:\Tools\Sysinternals"

# Programming Fonts
choco install anonymouspro -y --force
choco install sourcecodepro -y --force
choco install firacode -y --force
choco install hackfont -y --force
choco install cascadiacodepl -y --force

#choco install adobereader -y --force
#choco install zoom -y --force
#choco install docker-desktop -y --force
#choco install vscode-docker -y --force
#choco install paint.net -y --force
#choco install greenshot -y --force
#choco install slack -y --force
#choco install openvpn -y --force
#choco install microsoft-teams -y --force

# Git Repos
New-Item -Path "C:\GitHub" -ItemType Directory -ErrorAction SilentlyContinue
$githubs | ForEach-Object {
    Set-Location -Path "C:\GitHub"
    Write-Output "Cloning $_"
    Start-Process 'C:\Program Files\Git\bin\git.exe' -ArgumentList "clone $_" -NoNewWindow -Wait
}
