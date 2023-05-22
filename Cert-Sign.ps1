# Get Cert From Cert Store, Requires Cert Already Be Imported
$cert = (Get-ChildItem Cert:\CurrentUser\TrustedPublisher -CodeSigningCert)
# Asks user where scripts to sign are located
$ScriptToSign = (Get-ChildItem -Path (Read-Host -Prompt 'Get path') -Filter '*.ps1' | Select-Object Fullname).Fullname
Set-AuthenticodeSignature $ScriptToSign -Certificate $Cert
