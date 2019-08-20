New-Item -Path c:\traefik -ItemType Directory
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/TraefikForBC/5c89ed4036457be3f531962e865916b7f4a539f9/template_traefik.toml" -OutFile c:\traefik\traefik.toml

New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946  
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946  

docker pull stefanscherer/traefik-windows:v1.7.12