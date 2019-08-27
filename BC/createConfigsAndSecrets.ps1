param(
 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,
 
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroup,
 
 [Parameter(Mandatory=$True)]
 [string]
 $sqlServerName,
 
 [Parameter(Mandatory=$True)]
 [string]
 $poolName,
 
 [Parameter(Mandatory=$True)]
 [string]
 $originalDatabaseName
)

function Set-DockerSecret {
  param(
    [Parameter(Mandatory=$True)]
    [string]
    $secretName,
 
    [Parameter(Mandatory=$True)]
    [string]
    $secretValue
  )

  if (Test-Path ".\$secretName") {
    Remove-Item ".\$secretName"
  }
  Out-File -FilePath ".\$secretName" -NoNewline -InputObject $secretValue
  docker secret create $secretName ".\$secretName"
  Remove-Item ".\$secretName"
}

function Set-DockerConfig {
  param(
    [Parameter(Mandatory=$True)]
    [string]
    $configName,
 
    [Parameter(Mandatory=$True)]
    [string]
    $configValue
  )

  if (Test-Path ".\$configName") {
    Remove-Item ".\$configName"
  }
  Out-File -FilePath ".\$configName" -NoNewline -InputObject $configValue
  docker config create $configName ".\$configName"
  Remove-Item ".\$configName"
}

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
Install-Module -Name Az -AllowClobber -Force

Connect-AzAccount

$account = New-AzADServicePrincipal -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Sql/servers/$sqlServerName"
$applicationId = $account.ApplicationId

$Key = @()
for ($i = 0; $i -lt 32; $i++) {
    $Key += (Get-Random -Maximum 255)
}
$keyAsString = [string]::Join(",", $Key)

$accountSecret = $account.Secret | ConvertFrom-SecureString -Key $Key

$tenantId = (Get-AzContext).Tenant.Id

Set-DockerSecret -secretName bc_swarm_applicationId -secretValue $applicationId
Set-DockerSecret -secretName bc_swarm_accountSecret -secretValue $accountSecret
Set-DockerSecret -secretName bc_swarm_accountSecretkey -secretValue $keyAsString

Set-DockerConfig -configName bc_swarm_tenantId -configValue $tenantId
Set-DockerConfig -configName bc_swarm_resourceGroup -configValue $resourceGroup
Set-DockerConfig -configName bc_swarm_serverName -configValue $sqlServerName
Set-DockerConfig -configName bc_swarm_poolName -configValue $poolName
Set-DockerConfig -configName bc_swarm_originalDatabaseName -configValue $originalDatabaseName