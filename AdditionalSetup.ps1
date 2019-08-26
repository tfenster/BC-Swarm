
if (!(Get-NAVServerUser -ServerInstance NAV -ErrorAction Ignore | Where-Object { $_.UserName -eq $username })) {
    Write-Host "Set up SUPER user $username"
    New-NavServerUser -UserName $username -Password $securepassword NAV
    New-NavServerUserPermissionSet -UserName $username -PermissionSetId SUPER NAV
} else {
    Write-Host "User $username already exists"
}