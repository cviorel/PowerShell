# https://sandyzeng.com/hyper-v-remove-firmware-file-bootmgfw-efi/

$VMName = "Arch"
Get-VMFirmware -VMName $VMName | ForEach-Object { Set-VMFirmware -BootOrder ($_.Bootorder | Where-Object { $_.BootType -ne 'File' }) $_ }
