<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string]
 $location,

 [Parameter(Mandatory=$True)]
 [string]
 $name,

 [Parameter(Mandatory=$True)]
 [securestring]
 $adminPassword,

 [Parameter(Mandatory=$True)]
 [string]
 $email,

 [Parameter(Mandatory=$True)]
 [int]
 $numberOfWorkers,

 [Parameter(Mandatory=$False)]
 [string]
 $images = "",

 [Parameter(Mandatory=$False)]
 [string]
 $managerVmName = "mgr",

 [Parameter(Mandatory=$False)]
 [string]
 $managerVmSize = "Standard_D2s_v3",

 [Parameter(Mandatory=$False)]
 [string]
 $workerVmName = "worker",

 [Parameter(Mandatory=$False)]
 [string]
 $workerVmSize = "Standard_D8s_v3",

 [Parameter(Mandatory=$False)]
 [string]
 $adminUser = "VM-Administrator",

 [Parameter(Mandatory=$False)]
 [switch]
 $initial = $False,

 [Parameter(Mandatory=$False)]
 [string]
 $branch="master",

 [Parameter(Mandatory=$False)]
 [string]
 $additionalScriptMgr="",

 [Parameter(Mandatory=$False)]
 [string]
 $additionalScriptWorker="",

 [switch]
 $uploadSshPubKey

)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

# copied from https://stackoverflow.com/a/34383413 with a minimal change
Function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject,

        [switch]
        $NoRecurse
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )
            
            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"
$resourceGroupName = $name

if ($initial) {
    # sign in
    Write-Host "Logging in...";
    Login-AzAccount

    # select subscription
    Select-AzSubscription -SubscriptionID $subscriptionId;

    # Register RPs
    $resourceProviders = @("microsoft.network","microsoft.compute","microsoft.devtestlab","microsoft.resources");
    if($resourceProviders.length) {
        Write-Host "Registering resource providers"
        foreach($resourceProvider in $resourceProviders) {
            RegisterRP($resourceProvider);
        }
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. Creating resource group '$resourceGroupName' in location '$location'";
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";

$userid = (Get-AzADUser -UserPrincipalName ((Get-AzContext).Account.Id)).Id
$params = @{
    ResourceGroupName = $resourceGroupName 
    Name = "$name-deployment" 
    TemplateFile = ".\template.json" 
    TemplateParameterFile = ".\parameters.json"
    location = $location
    adminPassword = $adminPassword
    adminUsername = "$adminUser"
    virtualNetworkName = "${resourceGroupName}-vnet"
    dnsLabelPrefix = "$name"
    email = "$email"
    count = $numberOfWorkers
    virtualMachineNameMgr = "$managerVmName"
    publicIpAddressNameMgr = "${managerVmName}-ip"
    networkInterfaceNameMgr = "${managerVmName}-ni"
    networkSecurityGroupNameMgr = "${managerVmName}-nsg"
    virtualMachineSizeMgr = "$managerVmSize"
    vmssName = "$workerVmName"
    publicIpAddressNameWorker = "${workerVmName}-ip"
    networkSecurityGroupNameWorker = "${workerVmName}-nsg"
    virtualMachineSizeWorker = "$workerVmSize"
    branch = "$branch"
    userObjectId = $userid
    additionalScriptMgr = $additionalScriptMgr
    additionalScriptWorker = $additionalScriptWorker
}

if ($images -ne "") {
    $params += @{ 
        images = $images 
    }
}

$deployment = New-AzResourceGroupDeployment @params
if ($deployment.ProvisioningState -eq "Succeeded" -and $uploadSshPubKey) {
    Write-Host "Upload SSH key"
    $Secret = ConvertTo-SecureString -String (Get-Content "$HOME\.ssh\id_rsa.pub") -AsPlainText -Force 
    Set-AzKeyVaultSecret -VaultName "SwarmVault-$resourceGroupName" -Name 'sshPubKey' -SecretValue $Secret    
}