param(
 [Parameter(Mandatory=$True)]
 [string]
 $name,
 
 [Parameter(Mandatory=$True)]
 [string]
 $image
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

$customNavSettings = "customnavsettings=PublicODataBaseUrl=$restUrl,PublicSOAPBaseUrl=$soapUrl,PublicWebBaseUrl=$webclientUrl"
$webclientRule="PathPrefix:$webclientPart"
$soapRule="PathPrefix:${soapPart};ReplacePathRegex: ^${soapPart}(.*) /NAV/WS/`$1"
$restRule="PathPrefix:${restPart};ReplacePathRegex: ^${restPart}(.*) /NAV/OData/`$1"
$devRule="PathPrefix:${devPart};ReplacePathRegex: ^${devPart}(.*) /NAV/`$1"
$dlRule="PathPrefixStrip:${dlPart}"

docker service create `
--name $name --health-start-period 300s --network $network --hostname $hostname `
-e accept_eula=y -e accept_outdated=y -e usessl=n -e webserverinstance=$name -e publicdnsname=$publicDnsName -e $customNavSettings `
-e "folders=c:\run\my=https://github.com/tfenster/BC-Swarm/archive/master.zip\BC-Swarm-master" `
--label "traefik.web.frontend.rule=$webclientRule" --label "traefik.web.port=80" `
--label "traefik.soap.frontend.rule=$soapRule" --label "traefik.soap.port=7047" `
--label "traefik.rest.frontend.rule=$restRule" --label "traefik.rest.port=7048" `
--label "traefik.dev.frontend.rule=$devRule" --label "traefik.dev.port=7049" `
--label "traefik.dl.frontend.rule=$dlRule" --label "traefik.dl.port=8080" `
--label "traefik.enable=true" --label "traefik.frontend.entryPoints=https" `
--constraint "node.role!=manager" `
$image