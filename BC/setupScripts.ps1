# thanks to https://stackoverflow.com/users/103897/chris-hayes for https://stackoverflow.com/a/9368555
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

mkdir c:\scripts | out-null
Set-Location C:\scripts
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/BC/createConfigsAndSecrets.ps1" -OutFile C:\scripts\createConfigsAndSecrets.ps1
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/BC/createBCService.ps1" -OutFile C:\scripts\createBCService.ps1
Write-Host "Script folder prepared and downloaded all scripts" -ForegroundColor Green