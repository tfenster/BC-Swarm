New-Item -Path c:\traefik -ItemType Directory | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/TraefikForBC/5c89ed4036457be3f531962e865916b7f4a539f9/template_traefik.toml" -OutFile c:\traefik\traefik.toml | Out-Null

New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946 | Out-Null

Invoke-Expression "docker pull stefanscherer/traefik-windows:v1.7.12" | Out-Null

$ipaddress = (Get-NetIPAddress | Where-Object { $_.IPAddress.StartsWith("10.0.3") }).IPAddress
$result = Invoke-Expression "docker swarm init --advertise-addr $ipaddress"

if ($result -match "docker swarm join --token (?<Token>.+) ${ipaddress}:2377") {
    Write-Host $Matches.Token
}