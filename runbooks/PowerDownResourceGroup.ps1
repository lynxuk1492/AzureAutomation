workflow PowerDownResourceGroup
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
	$acc = Add-AzureRmAccount `
	        -ServicePrincipal `
	        -TenantId $servicePrincipalConnection.TenantId `
	        -ApplicationId $servicePrincipalConnection.ApplicationId `
	        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
catch 
    {
        if (!$servicePrincipalConnection)
	    {
	        $ErrorMessage = "Connection $connectionName not found."
	        throw $ErrorMessage
	    } 
        else
        {
	        Write-Error -Message $_.Exception
	        throw $_.Exception
	    }
	}
	
"Get all the VM in Resource Group $ResourceGroupName"
$VMs = Find-AzureRmResource -ResourceGroupNameContains $ResourceGroupName -ResourceType "Microsoft.Compute/virtualMachines"
	
"Loop thru each VM"
ForEach –parallel ($VM in $VMs)
	{
	"Stopping VM $($vm.name)"
	$res = Stop-AzurermVM -ResourceGroupName $ResourceGroupName -Name $vm.name	-Force 
	}
		
}