param(
 [Parameter(Mandatory=$True)]
 [string]
 $name,
 
 [Parameter(Mandatory=$True)]
 [string]
 $image,
 
 [Parameter(Mandatory=$False)]
 [string]
 $addInsUrl,
 
 [Parameter(Mandatory=$True)]
 [string]
 $navPassword,
 
 [Parameter(Mandatory=$True)]
 [string]
 $originalDatabaseName
)

$publicDnsName = Get-Content -Path "c:\traefik\externaldns.txt"

$network = "traefik-public"
$hostname = $publicDnsName.Substring(0, $publicDnsName.IndexOf("."))
$restPart = "/${name}rest/" 
$soapPart = "/${name}soap/"
$devPart = "/${name}dev/"
$dlPart = "/${name}dl/"
$webclientPart = "/$name/"
$baseUrl = "https://$publicDnsName"
$restUrl = $baseUrl + $restPart
$soapUrl = $baseUrl + $soapPart
$webclientUrl = $baseUrl + $webclientPart

$customNavSettings = "customnavsettings=PublicODataBaseUrl=$restUrl,PublicSOAPBaseUrl=$soapUrl,PublicWebBaseUrl=$webclientUrl,EnableSymbolLoadingAtServerStartup=true"
$webclientRule="PathPrefix:$webclientPart"
$soapRule="PathPrefix:${soapPart};ReplacePathRegex: ^${soapPart}(.*) /BC/WS/`$1"
$restRule="PathPrefix:${restPart};ReplacePathRegex: ^${restPart}(.*) /BC/OData/`$1"
$devRule="PathPrefix:${devPart};ReplacePathRegex: ^${devPart}(.*) /BC/`$1"
$dlRule="PathPrefixStrip:${dlPart}"

$folders = "folders=c:\run\my=https://github.com/tfenster/BC-Swarm/archive/master.zip\BC-Swarm-master"
if (-not [string]::IsNullOrEmpty($addInsUrl)) {
    $folders += ",C:\run\Add-ins=$addInsUrl"
}

docker service create `
--name $name --health-start-period 900s --health-timeout 900s --network $network --hostname $hostname `
-e accept_eula=y -e accept_outdated=y -e usessl=n -e webserverinstance=$name -e publicdnsname=$publicDnsName -e $customNavSettings `
-e "$folders" `
-e "databasename=$name" -e "OriginalDatabaseName=$originalDatabaseName" `
-e "username=$name" -e "password=$navPassword" `
--label "traefik.web.frontend.rule=$webclientRule" --label "traefik.web.port=80" `
--label "traefik.soap.frontend.rule=$soapRule" --label "traefik.soap.port=7047" `
--label "traefik.rest.frontend.rule=$restRule" --label "traefik.rest.port=7048" `
--label "traefik.dev.frontend.rule=$devRule" --label "traefik.dev.port=7049" `
--label "traefik.dl.frontend.rule=$dlRule" --label "traefik.dl.port=8080" `
--label "traefik.enable=true" --label "traefik.frontend.entryPoints=https" `
--secret "src=bc_swarm_applicationId,target=c:\ConfigsAndSecrets\bc_swarm_applicationId" `
--secret "src=bc_swarm_accountSecret,target=c:\ConfigsAndSecrets\bc_swarm_accountSecret" `
--secret "src=bc_swarm_accountSecretkey,target=c:\ConfigsAndSecrets\bc_swarm_accountSecretkey" `
--secret "src=bc_swarm_sqlPassword,target=c:\ConfigsAndSecrets\bc_swarm_sqlPassword" `
--config "src=bc_swarm_subscriptionId,target=c:\ConfigsAndSecrets\bc_swarm_subscriptionId" `
--config "src=bc_swarm_tenantId,target=c:\ConfigsAndSecrets\bc_swarm_tenantId" `
--config "src=bc_swarm_resourceGroup,target=c:\ConfigsAndSecrets\bc_swarm_resourceGroup" `
--config "src=bc_swarm_serverName,target=c:\ConfigsAndSecrets\bc_swarm_serverName" `
--config "src=bc_swarm_sqlUserName,target=c:\ConfigsAndSecrets\bc_swarm_sqlUserName" `
--config "src=bc_swarm_poolName,target=c:\ConfigsAndSecrets\bc_swarm_poolName" `
--config "src=bc_swarm_originalResourceGroup,target=c:\ConfigsAndSecrets\bc_swarm_originalResourceGroup" `
--config "src=bc_swarm_originalServerName,target=c:\ConfigsAndSecrets\bc_swarm_originalServerName" `
--constraint "node.role!=manager" `
--limit-memory 12G `
--detach `
$image