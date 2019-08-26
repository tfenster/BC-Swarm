function Get-SecretOrConfigValue {
    param(
        [Parameter(Mandatory=$True)]
        [string]
        $Name
    )
    $secretPath = "c:\ConfigsAndSecrets\$Name"
    if (Test-Path $secretPath) {  
        $value = Get-Content -Raw $secretPath
        return $value
    } else {
        Write-Error "Can't find config or secret $secretPath"
        return "UNDEFINED"
    }
}

$ApplicationId = Get-SecretOrConfigValue -Name "bc_swarm_applicationId"
$KeyAsString = Get-SecretOrConfigValue -Name "bc_swarm_accountSecretkey"
$TenantId = Get-SecretOrConfigValue -Name "bc_swarm_tenantId"
$Secret = Get-SecretOrConfigValue -Name "bc_swarm_accountSecret"
$ResourceGroup = Get-SecretOrConfigValue -Name "bc_swarm_resourceGroup"
$ServerName = Get-SecretOrConfigValue -Name "bc_swarm_serverName"
$PoolName = Get-SecretOrConfigValue -Name "bc_swarm_poolName"
$OriginalDatabaseName = Get-SecretOrConfigValue -Name "bc_swarm_originalDatabaseName"

$KeyStringArray = $KeyAsString.Split(",")
[array]$Key = foreach($number in $KeyStringArray) {([int]::parse($number))}

$DatabaseName = "$env:DatabaseName"

Write-Host "Import Azure modules"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
Install-Module -Name Az -AllowClobber -Force

$psCred = New-Object System.Management.Automation.PSCredential($ApplicationId , (ConvertTo-SecureString -String $Secret -Key $Key))

Write-Host "Azure login"
Connect-AzAccount -Credential $psCred -TenantId $TenantId -ServicePrincipal

Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $DatabaseName -ErrorAction Continue -errorVariable notThere 2>&1
if ($notThere) {
    Write-Host "Create database copy"
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    New-AzSqlDatabaseCopy -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $OriginalDatabaseName -CopyResourceGroupName $ResourceGroup -CopyServerName $ServerName -CopyDatabaseName $DatabaseName -ElasticPoolName $PoolName
    $stopwatch.Stop()
    Write-Host "Creating the copy took ${stopwatch.Elapsed.TotalMinutes} minutes"
} else {
    Write-Host "Database already exists"
}

# invoke default
. (Join-Path $runPath $MyInvocation.MyCommand.Name)