#Running this script is at your own risk
#Please provide the AzureAD licens group name in the parameters.
#This script only works with AzureAD Licens group Cloud-only.
#This only works with Windows 365 Enterprise edition.


#Parameters
#IF you dont have licens group for all Windows 365 Licens type, just leave them blank. But aware of the script will fail if you select a licens you dont have a licens group for.
param(
        #2VCPU 4GB Ram
        $W365_2vCPU_4GB_64GB = "",
        $W365_2vCPU_4GB_128GB = "",
        $W365_2vCPU_4GB_256GB = "",
        
        #2VCPU 8GM Ram
        $W365_2vCPU_8GB_128GB = "",
        $W365_2vCPU_8GB_256GB = "",

        #4VCPU 16GM Ram
        $W365_4vCPU_16GB_128GB = "",
        $W365_4vCPU_16GB_256GB = "",
        $W365_4vCPU_16GB_512GB = "",

        #8VCPU 32GM Ram
        $W365_8vCPU_32GB_128GB = "",
        $W365_8vCPU_32GB_256GB = "",
        $W365_8vCPU_32GB_512GB = ""
      )


#Function to check if MS.Graph module is installed and up-to-date
function invoke-graphmodule {
    $graphavailable = (find-module -name microsoft.graph)
    $vertemp = $graphavailable.version.ToString()
    Write-Output "Latest version of Microsoft.Graph module is $vertemp" | out-host

    foreach ($module in $modules){
        write-host "Checking module - " $module
        $graphcurrent = (get-installedmodule -name $module -ErrorAction SilentlyContinue)

        if ($graphcurrent -eq $null) {
            write-output "Module is not installed. Installing..." | out-host
            try {
                Install-Module -name $module -Force -ErrorAction Stop 
                Import-Module -name $module -force -ErrorAction Stop 

                }
            catch {
                write-output "Failed to install " $module | out-host
                write-output $_.Exception.Message | out-host
                Return 1
                }
        }
    }


    $graphcurrent = (get-installedmodule -name Microsoft.Graph.DeviceManagement.Functions)
    $vertemp = $graphcurrent.Version.ToString() 
    write-output "Current installed version of Microsoft.Graph module is $vertemp" | out-host

    if ($graphavailable.Version -gt $graphcurrent.Version) { write-host "There is an update to this module available." }
    else
    { write-output "The installed Microsoft.Graph module is up to date." | out-host }
}

#Function to connect to the MS.Graph PowerShell Enterprise App
function connect-msgraph {

    $tenant = get-mgcontext
    if ($tenant.TenantId -eq $null) {
        write-output "Not connected to MS Graph. Connecting..." | out-host
        try {
            Connect-MgGraph -Scopes "CloudPC.Read.All","CloudPC.ReadWrite.All" -ErrorAction Stop | Out-Null
        }
        catch {
            write-output "Failed to connect to MS Graph" | out-host
            write-output $_.Exception.Message | out-host
            Return 1
        }   
    }
    $tenant = get-mgcontext
    $text = "Tenant ID is " + $tenant.TenantId
    Write-Output "Connected to Microsoft Graph" | out-host
    Write-Output $text | out-host
}

#Function to connect to the MS.Graph PowerShell Enterprise App
function connect-aad {
    
    try{
        $AADtenant = Get-AzureADTenantDetail -ErrorAction Stop | Out-Null
    }
    catch{
        write-output "Not connected to Azure AD. Connecting..." | out-host
        try {
            Connect-AzureAD -ErrorAction Stop | Out-Null
        }
        catch {
            write-output "Failed to connect to Azure AD" | out-host
            write-output $_.Exception.Message | out-host
            Return 1
        }
    }
   
    $AADtenant = Get-AzureADTenantDetail
    $text = "Tenant ID is " + $AADtenant.ObjectId
    Write-Output "Connected to Azure AD" | out-host
    Write-Output $text | out-host

    }
  

#Function to check if AzureADPreview module is installed and up-to-date
function invoke-AzureADPreview {
    $AADPavailable = (find-module -name AzureADPreview)
    $vertemp = $AADPavailable.version.ToString()
    Write-Output "Latest version of AzureADPreview module is $vertemp" | out-host
    $AADPcurrent = (get-installedmodule -name AzureADPreview -ErrorAction SilentlyContinue) 

    if ($AADPcurrent -eq $null) {
        write-output "AzureADPreview module is not installed. Installing..." | out-host
        try {
            Install-Module AzureADPreview -Force -ErrorAction Stop
        }
        catch {
            write-output "Failed to install AzureADPreview Module" | out-host
            write-output $_.Exception.Message | out-host
            Return 1
        }
    }
    $AADPcurrent = (get-installedmodule -name AzureADPreview)
    $vertemp = $AADPcurrent.Version.ToString() 
    write-output "Current installed version of AzureADPreview module is $vertemp" | out-host


    if ($AADPavailable.Version -gt $AADPcurrent.Version) { write-host "There is an update to this module available." }
    else
    { write-output "The installed AzureADPreview module is up to date." | out-host }
}

#Function to set the profile to beta
function set-profile {
    Write-Output "Setting profile as beta..." | Out-Host
    Select-MgProfile -Name beta
}

#function to detect if AzureAD module is installed
function invoke-azureadcheck {
    try
    {
    Get-InstalledModule -Name AzureAD -ErrorAction Stop | Out-Null
    Write-Host "AzureAD module is installed" -ForegroundColor Red
    Return 1
    }
    
    catch
    {
    Write-Host "AzureAD module is not installed"
    Return 0
    }   
}

$modules = @("Microsoft.Graph.DeviceManagement.Functions",
                "Microsoft.Graph.DeviceManagement.Administration",
                "Microsoft.Graph.DeviceManagement.Enrolment",
                "Microsoft.Graph.DeviceManagement.Actions",
                "Microsoft.Graph.Users.Functions",
                "Microsoft.Graph.Users.Actions"
            )

$WarningPreference = 'SilentlyContinue'


#Command to check if AzureAD module is installed and exit if it is.
if (invoke-azureadcheck -eq 1) {
    write-host "The AzureAD module is not compatibile with AzureADPreivew" -ForegroundColor Red
    write-host "Please uninstall the AzureAD module, close all PowerShell sessions," -ForegroundColor Red
    Write-Host "and run this script again" -ForegroundColor Red
    Return 1
}


#Commands to load MS.Graph modules
if (invoke-graphmodule -eq 1) {
    write-output "Invoking Graph failed. Exiting..." | out-host
    Return 1
}

#Command to connect to MS.Graph PowerShell app
if (connect-msgraph -eq 1) {
    write-output "Connecting to Graph failed. Exiting..." | out-host
    Return 1
}

set-profile

#Commands to load AzureADPreview modules
if (invoke-AzureADPreview -eq 1) {
    write-output "Invoking AzureADPreview failed. Exiting..." | out-host
    Return 1
}

#Command to connect to AzureAD PowerShell app
if (connect-aad -eq 1) {
    write-output "Connecting to AzureAD failed. Exiting..." | out-host
    Return 1
}

function Show-Menu
{
    param (
        [string]$Title = 'Windows 365 Enterprise sizes'
    )
    Write-Host "Select the Size you want to resize to"
    Write-Host ""
    Write-Host "================ $Title ================"
    
    Write-Host "1: Windows 365 Enterprise 2 vCPU, 4 GB, 128 GB"
    Write-Host "2: Windows 365 Enterprise 2 vCPU, 4 GB, 256 GB"
    Write-Host "3: Windows 365 Enterprise 2 vCPU, 8 GB, 128 GB"
    Write-Host "4: Windows 365 Enterprise 2 vCPU, 8 GB, 256 GB"
    Write-Host "5: Windows 365 Enterprise 4 vCPU, 16 GB, 128 GB"
    Write-Host "6: Windows 365 Enterprise 4 vCPU, 16 GB, 256 GB"
    Write-Host "7: Windows 365 Enterprise 4 vCPU, 16 GB, 512 GB"
    Write-Host "8: Windows 365 Enterprise 8 vCPU, 32 GB, 128 GB"
    Write-Host "9: Windows 365 Enterprise 8 vCPU, 32 GB, 256 GB"
    Write-Host "10: Windows 365 Enterprise 8 vCPU, 32 GB, 512 GB"
    Write-Host "Q: Press 'Q' to quit."
    

}


#Lookup UserPrincipalName in AzureAD
try {
        $CloudPCName = Read-Host "Enter the Cloud PC Name you wish to resize"
        $CloudPC = Get-MgDeviceManagementVirtualEndpointCloudPC | where-object {$_.ManagedDeviceName -eq $CloudPCName}
        if(!($CloudPC)) {
        Write-Host "Unable to find Cloud PC: $CloudPCName"
        Write-Host "Ending script.."
        break
        }

        #output information about selected Cloud PC
        $Output = [PSCustomObject]@{
        "Cloud PC Name" = "$($CloudPC.ManagedDeviceName)"
        "Cloud PC Managed Device ID" = "$($CloudPC.ManagedDeviceId)"
        "Cloud PC AAD Device ID" = "$($CloudPC.AadDeviceId)"
        "UserPrincipalName" = "$($CloudPC.UserPrincipalName)"
        "Current Cloud PC Size" = "$($CloudPC.ServicePlanName)"
    }

    $Output


    #please select which size you wish to resize to.
    show-menu
    $selection = Read-Host "Please make a selection"
     switch ($selection){
         '1' { 
             $SKUName = "Windows 365 Enterprise 2 vCPU, 4 GB, 128 GB"
             $NewLicensGroup = $W365_2vCPU_4GB_128GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             } 
         '2' {
             $SKUName = "Windows 365 Enterprise 2 vCPU, 4 GB, 256 GB"
             $NewLicensGroup = $W365_2vCPU_4GB_256GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             } 
         '3' {
             $SKUName = "Windows 365 Enterprise 2 vCPU, 8 GB, 128 GB"
             $NewLicensGroup = $W365_2vCPU_8GB_128GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '4' {
             $SKUName = "Windows 365 Enterprise 2 vCPU, 8 GB, 256 GB"
             $NewLicensGroup = $W365_2vCPU_8GB_256GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '5' {
             $SKUName = "Windows 365 Enterprise 4 vCPU, 16 GB, 128 GB"
             $NewLicensGroup = $W365_4vCPU_16GB_128GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '6' {
             $SKUName = "Windows 365 Enterprise 4 vCPU, 16 GB, 256 GB"
             $NewLicensGroup = $W365_4vCPU_16GB_256GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '7' {
             $SKUName = "Windows 365 Enterprise 4 vCPU, 16 GB, 512 GB"
             $NewLicensGroup = $W365_4vCPU_16GB_512GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resiz Cloud PC: $CloudPCName to: $SKUName"
             }
         '8' {
             $SKUName = "Windows 365 Enterprise 8 vCPU, 32 GB, 128 GB"
             $NewLicensGroup = $W365_8vCPU_32GB_128GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '9' {
             $SKUName = "Windows 365 Enterprise 8 vCPU, 32 GB, 256 GB"
             $NewLicensGroup = $W365_8vCPU_32GB_256GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         '10'{
             $SKUName = "Windows 365 Enterprise 8 vCPU, 32 GB, 512 GB"
             $NewLicensGroup = $W365_8vCPU_32GB_512GB
             Write-Host "Once the resize has begun there is no way back."
             Write-Host "Are you sure you want to contiune resize Cloud PC: $CloudPCName to: $SKUName"
             }
         'q' {
             Write-Host "You have selected quit"
             Write-Host "Ending script"
             break
             }
     }


                $YesOrNo = Read-Host "Please enter your response (y/n)"
                while("y","n" -notcontains $YesOrNo )
                {
                  $YesOrNo = Read-Host "Please enter your response (y/n)"
                }
                  If ($YesOrNo -eq "n") {
                        Write-Host "You have selected 'NO'"
                        Write-Host "Ending script"
                        Break
                     }


           
           #Check If there is a available licens to use
           Write-Host "Checking if there is a $SKUName available..."
           
            #$SKUName = "Windows 365 Enterprise 2 vCPU, 8 GB, 128 GB"
            $SKUNameSplit = $SKUName -split ","

            #CPU
            $CPU = $SKUNameSplit[0]
            $CPU = $CPU -split " "
            $CPU = $CPU[3]
            #RAM
            $RAM = $SKUNameSplit[1]
            $RAM = $RAM -split " "
            $RAM = $RAM[1]
            #Drive
            $Drive = $SKUNameSplit[2]
            $Drive = $Drive -split " "
            $Drive = $Drive[1]

            $SkuPartNumber = "CPC_E_$($CPU)C_$($RAM)GB_$($Drive)GB​"

            $GetSKU = Get-AzureADSubscribedSku | Where-Object {$_.SkuPartNumber -eq $SkuPartNumber}

            If (!($GetSKU)){
            Write-Host "Unable to find Licens $SKUName in Azure AD. Please check if you have the licens available"
            Write-Host "Ending Script"
            Break
            }
            
            $UsedSKU = $GetSKu.ConsumedUnits
            $TotalSKU = $GetSKU.PrepaidUnits.Enabled
            If ($UsedSKU -ge $TotalSKU){
            Write-Host "There is not enough Licenses available."
            Write-Host "Please go and add more licenses and run the script again."
            Write-Host "Ending Script"
            Break
            }

            #Get Service Plan SKU for new Licens
            $GetSKU.ServicePlans | where {$_.ServicePlanName -match "CPC_"}
            $NewServiceplan = $GetSKU.ServicePlans | where {$_.ServicePlanName -match "CPC_"}
            $NewServicePlanID = $NewServiceplan.ServicePlanId

            #Checking user licens group
            $UserDetails = Get-AzureADUser -Filter "userPrincipalName eq '$($CloudPC.UserPrincipalName)'"
            $CurrentSKUPartNumber = $CloudPC.ServicePlanName
            $CurrentSKUPartNumber = $CurrentSKUPartNumber -split " "
            $CurrentSKUPartNumber = $CurrentSKUPartNumber[3] -split "/"

            #CPU
            $CurrentCPU = $CurrentSKUPartNumber[0]
            $CurrentCPU = $CurrentCPU -split "v"
            $CurrentCPU = $CurrentCPU[0]
            #RAM
            $CurrentRAM = $CurrentSKUPartNumber[1]
            $CurrentRAM = $CurrentRAM -split "G"
            $CurrentRAM = $CurrentRAM[0]
            #Drive
            $CurrentDrive = $CurrentSKUPartNumber[2]
            $CurrentDrive = $CurrentDrive -split "G"
            $CurrentDrive = $CurrentDrive[0]


            $CurrentSkuPartNumber = "CPC_E_$($CurrentCPU)C_$($CurrentRAM)GB_$($CurrentDrive)GB​"


            $GetCurrentSKU = Get-AzureADUserLicenseDetail -ObjectId $UserDetails.ObjectId | Where-Object {$_.SkuPartNumber -eq $CurrentSkuPartNumber}
            
            if ($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_2C_4GB_64GB​'){
            $CurrentLicensGroup = $W365_2vCPU_4GB_64GB
            } 
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_2C_4GB_128GB​'){
            $CurrentLicensGroup = $W365_2vCPU_4GB_128GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_2C_4GB_256GB​'){
            $CurrentLicensGroup = $W365_2vCPU_4GB_256GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_2C_8GB_128GB​'){
            $CurrentLicensGroup = $W365_2vCPU_8GB_128GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_2C_8GB_256GB​'){
            $CurrentLicensGroup = $W365_2vCPU_8GB_256GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_4C_16GB_128GB​'){
            $CurrentLicensGroup = $W365_4vCPU_16GB_128GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_4C_16GB_256GB​'){
            $CurrentLicensGroup = $W365_4vCPU_16GB_256GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_4C_16GB_512GB​'){
            $CurrentLicensGroup = $W365_4vCPU_16GB_512GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_8C_32GB_128GB​'){
            $CurrentLicensGroup = $W365_8vCPU_32GB_128GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_8C_32GB_256GB​'){
            $CurrentLicensGroup = $W365_8vCPU_8GB_256GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq 'CPC_E_8C_32GB_512GB​'){
            $CurrentLicensGroup = $W365_8vCPU_32GB_512GB
            }
            elseif($GetCurrentSKU.SkuPartNumber -eq $null){
            Write-Host "Not able to locate Windows 365 Enterprise sku assigned to the user"
            Write-Host "Go check the MEM portal for troubleshooting"
            Write-Host "Ending script"
            break
            }

            #Check licensgroup membership
            $CheckCurrentlicensGroupMemberShip = Get-AzureADUserMembership -ObjectId $UserDetails.ObjectId | Select-Object DisplayName,ObjectID | Where-Object {$_.DisplayName -eq $CurrentLicensGroup}
            if (!($CheckCurrentlicensGroupMemberShip)) {
            Write-Host "Unable to find User in licens group $CurrentLicensGroup"
            Write-Host "ending script"
            break
            }

            #Removing user from Licens Group
            try {
            Write-Host "Removeing user from $CurrentLicensGroup"
            Remove-AzureADGroupMember -ObjectId $CheckCurrentlicensGroupMemberShip.ObjectId -MemberId $UserDetails.ObjectId
            }
            catch {
               
            write-output $_.Exception.Message | out-host
                
            }


            #Assing user licens directly
            try {
            Write-Host "Assiging current licens directly to user: $($CloudPC.UserPrincipalName)"
             $LicenseSku = Get-AzureADSubscribedSku | Where {$_.SkuPartNumber -eq $GetCurrentSKU.SkuPartNumber}
             $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
             $License.SkuId = $LicenseSku.SkuId
             $AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses


             $AssignedLicenses.AddLicenses = $License
             Set-AzureADUserLicense -ObjectId $UserDetails.ObjectId -AssignedLicenses $AssignedLicenses
             

            }
            catch{
               
            write-output $_.Exception.Message | out-host
                
            }

            #Resize Cloud PC
            try{
            
                #initiate Resize to new sku
                write-host "starting resize of Cloud PC: $($CloudPC.ManagedDeviceName)"
                Start-Sleep -Seconds 45

                 $params = @{
	                TargetServicePlanId = $NewServicePlanID
                }

                Resize-MgDeviceManagementManagedDeviceCloudPc -ManagedDeviceId $cloudpc.ManagedDeviceId -BodyParameter $params
                

                #Get Cloud PC Resize information
                $Resizeprogress = Get-MgDeviceManagementVirtualEndpointCloudPC | where-object {$_.ManagedDeviceName -eq $CloudPCName}
                #Timer variables
                $Timer = [Diagnostics.Stopwatch]::StartNew()
                $TimerRetryInterval = "30"
                $Timerout = "900"

                #Check if Resize has started
                 #Check resize progress
                    While (($Timer.Elapsed.TotalSeconds -lt $Timerout) -and (-not ($Resizeprogress.Status -like "resizing"))) {
                    Start-Sleep -Seconds $TimerRetryInterval
                    $TotalSecs = [math]::Round($Timer.Elapsed.TotalSeconds, 0)
                    Write-Output "Resizeing of Cloud PC: $($CloudPC.ManagedDeviceName) is still in progress of starting. Checking again in $TimerRetryInterval seconds"
                    $Resizeprogress = Get-MgDeviceManagementVirtualEndpointCloudPC | where-object {$_.ManagedDeviceName -eq $CloudPCName}
                }
 
                $Timer.Stop()
                If ($Timer.Elapsed.TotalSeconds -gt $Timerout) {
                    Write-host "Cloud PC: $($CloudPC.ManagedDeviceName) did not start the resizeing with the timeout time."
                    Write-host "Login to the MEM portal to start troubleshooting"
                    Write-host "Ending script"
                    exit
     
                }
                
                
                
                #Check resize progress
                While (($Timer.Elapsed.TotalSeconds -lt $Timerout) -and (-not ($Resizeprogress.Status -like "provisioned"))) {
                    Start-Sleep -Seconds $TimerRetryInterval
                    $TotalSecs = [math]::Round($Timer.Elapsed.TotalSeconds, 0)
                    Write-Output "Reize of Cloud PC: $($CloudPC.ManagedDeviceName) has started but is not done. Checking again in $TimerRetryInterval seconds"
                    $Resizeprogress = Get-MgDeviceManagementVirtualEndpointCloudPC | where-object {$_.ManagedDeviceName -eq $CloudPCName}
                }
 
                $Timer.Stop()
                If ($Timer.Elapsed.TotalSeconds -gt $Timerout) {
                    Write-host "Cloud PC: $($CloudPC.ManagedDeviceName) did not finish resizeing within the given time."
                    Write-host "Login to the MEM portal to start troubleshooting"
                    Write-host "Ending script"
                    exit
     
                }


            }
            catch{
               
            write-output $_.Exception.Message | out-host
            break
                
            }



            #Remove Direct licens from user
            try {
             Write-Host "Removing direct licens: '$SKUName' from user: $($CloudPC.UserPrincipalName)"        
             $UserDetails = Get-AzureADUser -Filter "userPrincipalName eq '$($CloudPC.UserPrincipalName)'"
             $GetCurrentSKU = Get-AzureADUserLicenseDetail -ObjectId $UserDetails.ObjectId | Where-Object {$_.SkuPartNumber -eq $SkuPartNumber}

             $LicenseSku = $GetCurrentSKU
             $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
             $License.SkuId = $LicenseSku.SkuId
             $AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses


             $AssignedLicenses.RemoveLicenses = $License.SkuId
             Set-AzureADUserLicense -ObjectId $UserDetails.ObjectId -AssignedLicenses $AssignedLicenses

           

            
            }
            catch {
               
            write-output $_.Exception.Message | out-host
            break
                
            }



            #Add user to Licens group
            
            try {
            
            $NewAzureADLicensGroupName = Get-AzureADGroup -Filter "displayname eq '$NewLicensGroup'"
            Add-AzureADGroupMember -ObjectId $NewAzureADLicensGroupName.ObjectId -RefObjectId $UserDetails.ObjectId
            Write-Host "User: $($CloudPC.UserPrincipalName) Has been added to the new licens group: $NewLicensGroup"
           

            }
            catch {
               
            write-output $_.Exception.Message | out-host
            break
                
            }
          

            Write-Host "Resize of Cloud PC: $($CloudPC.ManagedDeviceName) is now done,"
            Write-Host "It will take a few minutes before you can sign in."
            Write-Host "Remember to 'Refresh' the overview of availalbe Cloud PC in the webportal or Remote Desktop Client"
            Write-Host "Ending script."

    
            
}
catch {
        #write-output "Failed to get Cloud PC: $CloudPCName" | out-host
        write-output $_.Exception.Message | out-host
            
}
