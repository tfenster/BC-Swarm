param(
 [Parameter(Mandatory=$True)]
 [string]
 $joinCommand,

 [Parameter(Mandatory=$False)]
 [string]
 $images
)

# Swarm setup
New-NetFirewallRule -DisplayName "Allow Swarm TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 2377,7946 | Out-Null
New-NetFirewallRule -DisplayName "Allow Swarm UDP" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 4789,7946 | Out-Null
Write-Host "join swarm"
Invoke-Expression $joinCommand

# Maybe pull images
Write-Host "pull $images"
if (-not [string]::IsNullOrEmpty($images)) {
    $imgArray = $images.Split(',');
    foreach ($img in $imgArray) {
        Write-Host "pull $img"
        Invoke-Expression "docker pull $img" | Out-Null
    }
}