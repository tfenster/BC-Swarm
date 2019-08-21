param(
 [Parameter(Mandatory=$True)]
 [string]
 $location,

 [Parameter(Mandatory=$True)]
 [string]
 $name,

 [Parameter(Mandatory=$True)]
 [string]
 $email
)

# Traefik setup
$traefikImg = "stefanscherer/traefik-windows:v1.7.12"
New-Item -Path c:\traefik -ItemType Directory | Out-Null
New-Item -Path c:\traefik\my -ItemType Directory | Out-Null
New-Item -Path c:\traefik\config -ItemType Directory | Out-Null
New-Item -Path c:\traefik\config\acme.json | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/template_traefik.toml" -OutFile c:\traefik\template_traefik.toml | Out-Null

$externaldns = "$name.$location.cloudapp.azure.com"
$template = Get-Content 'c:\traefik\template_traefik.toml' -Raw
$expanded = Invoke-Expression "@`"`r`n$template`r`n`"@"
$expanded | Out-File "c:\traefik\config\traefik.toml" -Encoding ASCII

Invoke-Expression "docker pull $traefikImg" | Out-Null

# Swarm setup
New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946 | Out-Null

$ipaddress = (Get-NetIPAddress | Where-Object { $_.IPAddress.StartsWith("10.0.3") }).IPAddress
$result = Invoke-Expression "docker swarm init --advertise-addr $ipaddress"

if ([string]::Concat($result) -match "docker swarm join --token (?<Token>.+) ${ipaddress}:2377") {
    Write-Host ("docker swarm join --token " + $matches.Token + " ${ipaddress}:2377")
    Invoke-Expression "docker network create --driver=overlay traefik-public" | Out-Null
    Invoke-Expression "docker service create --name traefik --publish 80:80 --publish 443:443 --publish 8080:8080 --mount type=bind,source=c:/traefik/config,target=c:/etc/traefik --mount type=npipe,source=\\.\pipe\docker_engine,target=\\.\pipe\docker_engine --network traefik-public --label ""traefik.enable=true"" --label ""traefik.port=8080"" --constraint ""node.role==manager"" $traefikImg" | Out-Null
} else {
    Write-Host "Swarm init has failed: $result"
}