
if (!(Get-NAVServerUser -ServerInstance $ServerInstance -ErrorAction Ignore | Where-Object { $_.UserName -eq $username })) {
    Write-Host "Set up SUPER user $username"
    New-NavServerUser -UserName $username -Password $securepassword $ServerInstance -LanguageId 'de-DE' -Force
    New-NavServerUserPermissionSet -UserName $username -PermissionSetId SUPER $ServerInstance
} else {
    Write-Host "User $username already exists"
}

Write-Host "Check tenant state and optionally start data upgrade"
$tenantState = Get-NAVTenant -ServerInstance $ServerInstance -tenant default

if ($tenantState.State -eq "OperationalDataUpgradePending") {
    Write-Host "Tenant default needs data upgrade"
    Restart-NAVServerInstance $ServerInstance
    Start-NAVDataUpgrade -Tenant default $ServerInstance -Force
    while ($tenantState.State -ne "Operational") {
        Write-Host "Waiting for upgrade to finish"
        Start-Sleep -Seconds 30
        $tenantState = Get-NAVTenant -ServerInstance $ServerInstance -tenant default
    }
}
