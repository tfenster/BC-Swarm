
if (!(Get-NAVServerUser -ServerInstance NAV -ErrorAction Ignore | Where-Object { $_.UserName -eq $username })) {
    Write-Host "Set up SUPER user $username"
    New-NavServerUser -UserName $username -Password $securepassword NAV -LanguageId 'de-DE' -Force
    New-NavServerUserPermissionSet -UserName $username -PermissionSetId SUPER NAV
} else {
    Write-Host "User $username already exists"
}

Write-Host "Check tenant state and optionally start data upgrade"
$tenantState = Get-NAVTenant -ServerInstance NAV -tenant default

if ($tenantState.State -eq "OperationalDataUpgradePending") {
    Write-Host "Tenant default needs data upgrade"
    Restart-NAVServerInstance NAV
    Start-NAVDataUpgrade -Tenant default NAV -Force
    while ($tenantState.State -ne "Operational") {
        Write-Host "Waiting for upgrade to finish"
        Start-Sleep -Seconds 30
        $tenantState = Get-NAVTenant -ServerInstance NAV -tenant default
    }
}
