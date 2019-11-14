param(
 [Parameter(Mandatory=$True)]
 [string]
 $externaldns,

 [Parameter(Mandatory=$True)]
 [string]
 $email
)


# Swarm setup
New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Voting app" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5000,5001 | Out-Null

$ipaddress = (Get-NetIPAddress | Where-Object { $_.IPAddress.StartsWith("10.0.3") }).IPAddress
$result = Invoke-Expression "docker swarm init --advertise-addr $ipaddress"

if ([string]::Concat($result) -match "docker swarm join --token (?<Token>.+) ${ipaddress}:2377") {
    Write-Host ("docker swarm join --token " + $matches.Token + " ${ipaddress}:2377")
    Invoke-Expression "docker network create --driver=overlay traefik-public" | Out-Null
    Start-Sleep -Seconds 10
    mkdir c:\compose
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/master/Bare Swarm/docker-compose.yml" -OutFile c:\compose\docker-compose.yml
    Invoke-Expression "docker stack deploy -c c:\compose\docker-compose.yml base"
} else {
    Write-Host "Swarm init has failed: $result"
}