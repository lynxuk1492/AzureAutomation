workflow PowerUpResourceGroup
{
	param( 
	   [parameter(Mandatory=$true)]		
       [string]$ResourceGroupName 
     ) 
	
	$connectionName = "AzureRunAsConnection"
	try
	{
	    # Get the connection "AzureRunAsConnection "
	    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
	
	    "Logging in to Azure..."
	    Add-AzureRmAccount `
	        -ServicePrincipal `
	        -TenantId $servicePrincipalConnection.TenantId `
	        -ApplicationId $servicePrincipalConnection.ApplicationId `
	        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
	}
	catch {
	    if (!$servicePrincipalConnection)
	    {
	        $ErrorMessage = "Connection $connectionName not found."
	        throw $ErrorMessage
	    } else{
	        Write-Error -Message $_.Exception
	        throw $_.Exception
	    }
	}
	
	"Get all the VM in the Resource Gtoup"
	$ResourceGroupName
	$VMs = Find-AzureRmResource -ResourceGroupNameContains $ResourceGroupName -ResourceType "Microsoft.Compute/virtualMachines"
	
	"Loop thru each vm"
	$ErrorActionPreference = 'SilentlyContinue'	
	ForEach ($VM in $VMs)
	{
		"Test Each VM ($vm.name)"
		If ($vm.tags.Count -ne 0)
		{	
			If ($VM.Tags.ContainsValue("Early") -eq "True")
			{
				"Finding Early Start VMs"
				$vm.name
				Start-azurermvm -ResourceGroupName $ResourceGroupName -Name $vm.name
			}
		}
	}	
}