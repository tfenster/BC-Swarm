### deployment
.\deploy.ps1 -subscriptionId 'abc123' -location 'WestEurope' -adminPassword (ConvertTo-SecureString -String 'SuperSecret' -AsPlainText -Force) -email 'tobias.fenster@cosmoconsult.com' -numberOfWorkers 3 -branch 'master' -uploadSshPubKey -name 'bare' -initial

### If an error occurs and points to a correlation id: 
Get-AzureRMLog -CorrelationId f1143dbb-ca01-4696-9919-5bf1f985ca7e -DetailedOutput

### If you want to see the output of the script extensions:
$script = Get-AzureRmVMDiagnosticsExtension -VMName mgr -ResourceGroupName tfeswarm5 -Name script1 -Status
Write-Host $script.SubStatuses[0].Message

### Remove Resource Group
Remove-AzResourceGroup -force -asjob -Name bare

### Allow ping 
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow