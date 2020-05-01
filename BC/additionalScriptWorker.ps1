param(
    [Parameter(Mandatory = $False)]
    [string]
    $branch = "master",

    [Parameter(Mandatory = $False)]
    [switch]
    $restart
)

if (-not $restart) {
    New-Item -Path c:\programdata\navcontainerhelper -ItemType Directory | Out-Null
    New-Item -Path C:\programdata\navcontainerhelper\Extensions -ItemType Directory | Out-Null
}