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
	
    "Get all the VM in Resource Group $ResourceGroupName"
    $ResList = Find-AzureRmResource -TagName Early -TagValue True 
    
    "Loop thru each vm"
    ForEach –parallel ($Res in $ResList)
    {
        If ($Res.ResourceGroupName -eq $ResourceGroupName -and $Res.ResourceType -eq "Microsoft.Compute/virtualMachines")
        {
            $VMStatus = (Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $Res.Name -Status).Statuses.Code |where {$_.SubString(0,10) -eq 'PowerState'}
            If ($VMStatus -ne 'PowerState/running')
            {
                "Powering up (early) $($Res.Name)"
                Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $Res.Name
            }
        }
    }

    $ResList = Find-AzureRmResource  -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupNameContains $ResourceGroupName
    
    "Loop thru each vm"
    ForEach –parallel ($Res in $ResList)
    {
        $VMStatus = (Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $Res.Name -Status).Statuses.Code |where {$_.SubString(0,10) -eq 'PowerState'}
        If ($VMStatus -ne 'PowerState/running')
            {
                "Powering up $($Res.Name)"
                Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $Res.Name
            }
    }

}