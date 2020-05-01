param(
    [Parameter(Mandatory = $False)]
    [string]
    $branch = "master",

    [Parameter(Mandatory = $False)]
    [switch]
    $restart,

    [Parameter(Mandatory=$True)]
    [string]
    $externaldns
)

if (-not $restart) {
    New-Item -Path c:\programdata\navcontainerhelper -ItemType Directory | Out-Null
    New-Item -Path C:\programdata\navcontainerhelper\Extensions -ItemType Directory | Out-Null
    New-Item -Path C:\iac\compose-docker-automation -ItemType Directory | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/tfenster/BC-Swarm/$branch/BC/docker-compose.yml.template" -OutFile C:\iac\compose-docker-automation\docker-compose.yml.template
    $template = Get-Content 'c:\iac\compose-docker-automation\docker-compose.yml.template' -Raw
    $expanded = Invoke-Expression "@`"`r`n$template`r`n`"@"
    $expanded | Out-File "c:\iac\compose-docker-automation\docker-compose.yml" -Encoding ASCII

    Invoke-Expression "docker stack deploy -c c:\iac\compose-docker-automation\docker-compose.yml docker-automation"
}