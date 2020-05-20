### deployment
$subscriptionId = 'abc123'
$branch = 'master'
$name = 'swarn'
$adminPassword = 'Super5ecret!'
$workerVmSize = 'Standard_E8s_v3'

.\deploy.ps1 -subscriptionId $subscriptionId -location 'WestEurope' -adminPassword (ConvertTo-SecureString -String $adminPassword -AsPlainText -Force) -email 'tobias.fenster@cosmoconsult.com' -numberOfWorkers 2 -branch $branch -additionalScriptMgr "https://raw.githubusercontent.com/tfenster/BC-Swarm/$branch/BC/additionalScriptMgr.ps1" -additionalScriptWorker "https://raw.githubusercontent.com/tfenster/BC-Swarm/$branch/BC/additionalScriptWorker.ps1" -uploadSshPubKey -workerVmSize $workerVmSize -name $name -initial

### add private key if you know what you are doing
Invoke-Expression "scp $HOME\.ssh\id_rsa vm-administrator@$name.westeurope.cloudapp.azure.com:c:\users\vm-administrator\.ssh\"

### remove
Remove-AzResourceGroup -force -asjob -Name $name