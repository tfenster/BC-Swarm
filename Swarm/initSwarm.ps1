param(
 [Parameter(Mandatory=$True)]
 [string]
 $externaldns,

 [Parameter(Mandatory=$True)]
 [string]
 $email
)

# Traefik setup
$traefikImg = "stefanscherer/traefik-windows:v1.7.12"
New-Item -Path c:\traefik -ItemType Directory | Out-Null
New-Item -Path c:\traefik\config -ItemType Directory | Out-Null
New-Item -Path c:\traefik\config\acme.json | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/Swarm/template_traefik.toml" -OutFile c:\traefik\template_traefik.toml | Out-Null

$template = Get-Content 'c:\traefik\template_traefik.toml' -Raw
$expanded = Invoke-Expression "@`"`r`n$template`r`n`"@"
$expanded | Out-File "c:\traefik\config\traefik.toml" -Encoding ASCII

# Swarm setup
New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946 | Out-Null

Out-File -FilePath c:\traefik\externaldns.txt -InputObject $externaldns

$ipaddress = (Get-NetIPAddress | Where-Object { $_.IPAddress.StartsWith("10.0.3") }).IPAddress
$result = Invoke-Expression "docker swarm init --advertise-addr $ipaddress"

if ([string]::Concat($result) -match "docker swarm join --token (?<Token>.+) ${ipaddress}:2377") {
    Write-Host ("docker swarm join --token " + $matches.Token + " ${ipaddress}:2377")
    Invoke-Expression "docker network create --driver=overlay traefik-public" | Out-Null
    Start-Sleep -Seconds 10
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/Swarm/docker-compose.yml" -OutFile c:\traefik\docker-compose.yml
    Invoke-Expression "docker stack deploy -c c:\traefik\docker-compose.yml base"
} else {
    Write-Host "Swarm init has failed: $result"
}

Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/BC/setupScripts.ps1" -OutFile setupScripts.ps1 ; .\setupScripts.ps1
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
Install-Module -Name Az -AllowClobber -Force