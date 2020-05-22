param(
    [Parameter(Mandatory = $False)]
    [string]
    $branch = "master",

    [Parameter(Mandatory = $False)]
    [switch]
    $restart
)

if (-not $restart) {
    # default folders
    New-Item -Path c:\programdata\navcontainerhelper -ItemType Directory | Out-Null
    New-Item -Path C:\programdata\navcontainerhelper\Extensions -ItemType Directory | Out-Null

    # initialize NVMe disk -> L-Family doesn't support nested virt
    <#Initialize-Disk (Get-Disk -FriendlyName 'Microsoft NVMe Direct Disk').Number
    New-Partition -DiskNumber (Get-Disk -FriendlyName 'Microsoft NVMe Direct Disk').Number -DriveLetter s -UseMaximumSize
    Format-Volume -DriveLetter S -FileSystem NTFS -Confirm:$false#>

    # relocate docker data
    <#Stop-Service docker
    New-Item -Path 'd:\dockerdata' -ItemType Directory | Out-Null
    $dockerDaemonConfig = @"
{
    `"data-root`": `"d:\\dockerdata`"
}
"@
    $dockerDaemonConfig | Out-File "c:\programdata\docker\config\daemon.json" -Encoding ascii
    Start-Service docker#>

    # configure page file
    $pagefile = Get-WmiObject -Query "Select * From Win32_PageFileSetting"
    Set-CimInstance -Query "SELECT * FROM Win32_ComputerSystem" -Property @{AutomaticManagedPagefile = "False" }
    $PageFileSize = [int] ((Get-Volume -DriveLetter d).Size * 75 / 100 / 1024 / 1024)
    $PageFileSizeMax = 100 * 1000
    if ($PageFileSize -gt $PageFileSizeMax) {
        $PageFileSize = $PageFileSizeMax
    }
    $pagefile.Delete()
    Set-WMIInstance -class Win32_PageFileSetting -Arguments @{name = "d:\pagefile.sys"; InitialSize = $PageFileSize; MaximumSize = $PageFileSize }

    Restart-Computer -Force
}