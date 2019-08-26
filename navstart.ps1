function Get-SecretOrConfigValue {
    param(
        [Parameter(Mandatory=$True)]
        [string]
        $Name
    )
    if (Test-Path "c:\$Name") {  
        $value = Get-Content -Raw "c:\$Name"
        return $value
    } else {
        Write-Error "Can't find config or secret $Name"
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

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
Install-Module -Name Az -AllowClobber -Force

$psCred = New-Object System.Management.Automation.PSCredential($ApplicationId , (ConvertTo-SecureString -String $Secret -Key $Key))

Write-Host "Azure login"
Connect-AzAccount -Credential $psCred -TenantId $TenantId -ServicePrincipal

Write-Host "Create database copy"
New-AzSqlDatabaseCopy -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $OriginalDatabaseName -CopyResourceGroupName $ResourceGroup -CopyServerName $ServerName -CopyDatabaseName $DatabaseName -ElasticPoolName $PoolName -Verbose

# invoke default
. (Join-Path $runPath $MyInvocation.MyCommand.Name)