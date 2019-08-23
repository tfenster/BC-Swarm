$ApplicationId = "72f0f77c-ddf5-4e14-909c-0ee129f6c5db"
$Key = (3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5,35,43)
$TenantId = "539f23a3-6819-457e-bd87-7835f4122217"
$Secret = "76492d1116743f0423413b16050a5345MgB8AGIAcQBXAFMATgBOADQAZwA0ADQAcgBKAFIARgBPADYAMABXAFYARABiAFEAPQA9AHwANwBjAGUANQA1ADMAZAA4AGQAZAA5AGIANgBkADIAYQAwADcAMgAxADAAOQAyADQAZAAwADIANwAyADkAMQBiAGEAMgAwADUAMABjAGUAZQAwAGUAYwAwADcAZABkADQAYgA5AGIAMgA5ADUAYwBhADYAOQAwADMANQA4ADAAOQAzAGIANAA1ADYAZAAyADcAMwA2AGEAOQAwAGMANgAyAGMAMQBkAGEAYQAxAGYANgBiADMAOAA5AGQAYQAyAGEAMgBhADIAMgBmADAANgA5AGEAZgA5ADgAOAA5ADcANwAzAGYAOQAzADEAZAA0AGIAYQBkADcAYwBiAGIAMwBlADgAYwBjADcAYwAzADMANgAwADcANgBiAGYAMgBkAGIAMwBjADgAOQAyADUAYwA0AGQAZAAwADQAMABjADYAZAA="
$ResourceGroup = "swarm2"
$ServerName = "bc-sql"
$PoolName = "bc-pool"
$OriginalDatabaseName = "update"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name Az -AllowClobber -Force

$psCred = New-Object System.Management.Automation.PSCredential($ApplicationId , (ConvertTo-SecureString -String $Secret -Key $Key))

Write-Host "Azure login"
Connect-AzAccount -Credential $psCred -TenantId $TenantId -ServicePrincipal

Write-Host "Create database copy"
New-AzSqlDatabaseCopy -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $OriginalDatabaseName -CopyResourceGroupName $ResourceGroup -CopyServerName $ServerName -CopyDatabaseName $DatabaseName -ElasticPoolName $PoolName

# invoke default
. (Join-Path $runPath $MyInvocation.MyCommand.Name)