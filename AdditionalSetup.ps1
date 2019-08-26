Write-Host "Set up SUPER user $username"
New-NavServerUser -UserName $username -Password $securepassword NAV
New-NavServerUserPermissionSet -UserName $username -PermissionSetId SUPER NAV