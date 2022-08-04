
[CmdletBinding()]
param(
    #Welcome Email Attribute Check
    [parameter(HelpMessage = "Specify an extension Attribute between 1 - 15 you want the script to use. e.g. extensionAttribute3")]
    [string]$ExstensionAttributeKey = "extensionAttribute3",

    [parameter(HelpMessage = "Value of exstension Attribute e.g. CPCWelcomeMailHaveBeenSent")]
    [string]$ExstensionAttributeValue = "CPCWelcomeMailHaveBeenSent",

    #Mail Contenct path
    [parameter(HelpMessage = "Mail content path e.g. C:\temp\message.html")]
    [string]$MailContentPath = "E:\GitHubRepo\BicepIaC\AVD\message.html",

    #Email Attachment
    [parameter(HelpMessage = "Leave this blank if no email attachment is required, else specify the location to an attachment. e.g. C:\temp\attachment.pdf")]
    [string]$EmailAttachment = "",

    #Send Email Variable
    [parameter(HelpMessage = "Email Subject of the email")]
    [string]$EmailSubject = "AVD Test Mail"

    # [Parameter(mandatory = $false)]
    # [string]$HostpoolResourceGroupName = $HostpoolName,

    # [Parameter(mandatory = $true)]
    # [string]$ResourceGroupNames = $ResourceGroupNames
)



#################################################################################################################################################
###############################################--------------- Funcations ---------------########################################################
#################################################################################################################################################

#Function to check if MS.Graph module is installed and up-to-date
function invoke-graphmodule {
    $graphavailable = (Find-Module -Name microsoft.graph)
    $vertemp = $graphavailable.version.ToString()
    Write-Output "Latest version of Microsoft.Graph module is $vertemp" | Out-Host

    foreach ($module in $modules) {
        Write-Host "Checking module - " $module
        $graphcurrent = (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue)

        if ($null -eq $graphcurrent) {
            Write-Output "Module is not installed. Installing..." | Out-Host
            try {
                Install-Module -Name $module -Force -ErrorAction Stop
                Import-Module -Name $module -Force -ErrorAction Stop

            }
            catch {
                Write-Output "Failed to install " $module | Out-Host
                Write-Output $_.Exception.Message | Out-Host
                Return 1
            }
        }
    }
    $graphcurrent = (Get-InstalledModule -Name Microsoft.Graph.DeviceManagement.Functions)
    $vertemp = $graphcurrent.Version.ToString()
    Write-Output "Current installed version of Microsoft.Graph module is $vertemp" | Out-Host

    if ($graphavailable.Version -gt $graphcurrent.Version) {
        Write-Host "There is an update to this module available."
    }
    else {
        Write-Output "The installed Microsoft.Graph module is up to date." | Out-Host
    }
}


function connect-msgraph {
    $tenant = Get-MgContext
    if ($null -eq $tenant.TenantId) {
        Write-Output "Not connected to MS Graph. Connecting..." | Out-Host
        try {
            Connect-MgGraph -Scopes $GraphAPIPermissions -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Output "Failed to connect to MS Graph" | Out-Host
            Write-Output $_.Exception.Message | Out-Host
            Return 1
        }
    }
    $tenant = Get-MgContext
    $text = "Tenant ID is " + $tenant.TenantId
    Write-Output "Connected to Microsoft Graph" | Out-Host
    Write-Output $text | Out-Host
}

#Function to set the profile to beta
function set-profile {
    Write-Output "Setting profile as beta..." | Out-Host
    Select-MgProfile -Name beta
}

$modules = @("Microsoft.Graph.Authentication",
    "Microsoft.Graph.Users.Actions",
    "Microsoft.Graph.DeviceManagement.Administration",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Identity.DirectoryManagement",
    "Microsoft.Graph.DeviceManagement.Functions"
)

$WarningPreference = 'SilentlyContinue'

[String]$GraphAPIPermissions = @(
    "CloudPC.Read.All",
    "User.Read.all",
    "Directory.ReadWrite.All",
    "Mail.Send",
    "Device.Read.All",
    "Directory.AccessAsUser.All"
)

#Commands to load MS.Graph modules
if (invoke-graphmodule -eq 1) {
    Write-Output "Invoking Graph failed. Exiting..." | Out-Host
    Return 1
}

#Command to connect to MS.Graph PowerShell app
if (connect-msgraph -eq 1) {
    Write-Output "Connecting to Graph failed. Exiting..." | Out-Host
    Return 1
}

set-profile

#Check if Email content is reachable..
Write-Host "Checking if the email content is reachable..."
try {
    Write-Host "Gathering Email content"
    $EmailBody = Get-Content $MailContentPath -Raw
    $EmailBody = @"
$EmailBody
"@
}
catch {
    Write-Output "Failed to get Email content" | Out-Host
    Write-Output $_.Exception.Message | Out-Host
    break
}


#Get All Cloud PCDevice
$AllCPCDevices = Get-MgDevice  # -Filter "startsWith(Displayname,'TEUS')"
Foreach ($CPCDeviceInfo in $AllCPCDevices) {
    #Check if Cloud PC is actived
    if ($CPCDeviceInfo.AccountEnabled -eq $true) {
        Write-Output "Cloud PC are activated..."

        #Check For if Welcome mail has been sent before
        $Attributecheck = $CPCDeviceInfo.ExtensionAttributes.$ExstensionAttributeKey
        if (($Attributecheck -eq $ExstensionAttributeValue)) {
            Write-Output "The Attribute is not Configured, so Proceeding for Email Trigger and Attribute set $($CPCDeviceInfo.DisplayName) Machine... "

            #Check if Cloud PC is done priovision
            try {
                $ProvisionStatus = Get-AzVM | Where-Object { $_.Name -eq $CPCDeviceInfo.DisplayName }
                Write-Output " Machine Provision Status check..."
                # $ProvisionStatus = Get-MgDevice | where-object { $_.ManagedDeviceName -eq $CPCDeviceInfo.DisplayName }
                if ($ProvisionStatus.ProvisioningState -eq "Succeeded") {
                    Write-Host ""
                    Write-Host "Cloud PC: '$($CPCDeviceInfo.DisplayName)' has been provisioned correct and is ready to be logged into."

                    #Gathering user information
                    Write-Host "Gathering User information"
                    try {
                        $UserID = Get-AzWvdSessionHost `
                            -HostPoolName "t-avd-hp" `
                            -ResourceGroupName "t-avd-hp" | Where-Object { $_.Name.Split('/')[1] -eq $CPCDeviceInfo.DisplayName }

                        Write-Host "Cloud PC: '$($CPCDeviceInfo.DisplayName)' Primary user is: '$($UserID.AssignedUser)'"
                        Write-Host "Finding Email Address for user: '$($UserID.AssignedUser)'"
                        $UserInformation = Get-MgUser -Filter "userPrincipalName eq '$($UserID.AssignedUser)'"
                        $PrimarySMTP = $UserInformation.ProxyAddresses -clike 'SMTP:*' -split ":"
                        $PrimarySMTP = $PrimarySMTP[1]
                        Write-Host "Primary SMTP for user '$($UserInformation.UserPrincipalName)' is: '$PrimarySMTP'"

                        # $UserID = Get-AzWvdSessionHost | where-object { $_.Name -eq $CPCDeviceInfo.DisplayName }
                        # write-host "Cloud PC: '$($CPCDeviceInfo.DisplayName)' Primary user is: '$($UserID.UserPrincipalName)'"
                        # write-host "Finding Email Address for user: '$($UserID.UserPrincipalName)'"
                        ## $UserInformation = Get-AzureADUser -Filter "userPrincipalName eq '$($UserID.UserPrincipalName)'"
                        # $UserInformation = Get-MgUser -Filter "userPrincipalName eq '$($UserID.AssignedUser)'"
                        # $PrimarySMTP = $UserInformation.ProxyAddresses -clike 'SMTP:*' -split ":"
                        # $PrimarySMTP = $PrimarySMTP[1]
                        # write-host "Primary SMTP for user '$($UserInformation.UserPrincipalName)' is: '$PrimarySMTP'"

                        # Gather Users Information
                        # Write-Host "Cloud FirstName : '$($UserInformation.GivenName)' LastName : '$($UserInformation.Surname)'"
                        $Expression = "`$OutputBody = `@""`n`r$EmailBody`n`r""`@"
                        Invoke-Expression $Expression
                        # Write-Output "$($OutputBody)"
                    }
                    catch {
                        Write-Output "Unable to get user information" | Out-Host
                        Write-Output $_.Exception.Message | Out-Host
                        break
                    }



                    #Send email

                    #Get UserID from admin
                    $EmailUserDetails = Get-MgContext
                    $EmailUserDetails = Get-MgUser -Filter "userPrincipalName eq '$($EmailUserDetails.Account)'"

                    #Get File Name and Base64 string
                    if ($EmailAttachment) {

                        $AttachmentFileName = ( Get-Item -Path $EmailAttachment).name
                        $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($EmailAttachment))
                        $params = @{
                            Message         = @{
                                Subject      = $EmailSubject
                                Body         = @{
                                    ContentType = "HTML"
                                    Content     = $OutputBody
                                }
                                ToRecipients = @(
                                    @{
                                        EmailAddress = @{
                                            Address = $PrimarySMTP
                                        }
                                    }
                                )
                                Attachments  = @(
                                    @{
                                        "@odata.type" = "#microsoft.graph.fileAttachment"
                                        Name          = "$AttachmentFileName"
                                        ContentType   = "text/plain"
                                        ContentBytes  = $base64string

                                    }


                                )

                            }
                            SaveToSentItems = "false"
                        }

                    } else {

                        $params = @{
                            Message         = @{
                                Subject      = $EmailSubject
                                Body         = @{
                                    ContentType = "HTML"
                                    Content     = $OutputBody
                                }
                                ToRecipients = @(
                                    @{
                                        EmailAddress = @{
                                            Address = $PrimarySMTP
                                        }
                                    }
                                )

                            }
                            SaveToSentItems = "false"
                        }
                    }

                    Send-MgUserMail -UserId $EmailUserDetails.Id -BodyParameter $params

                    try {
                        #Set Attribute on Azure AD Device
                        Write-Host "Setting Attribute on AzureAD Device:'$($CPCDeviceInfo.DisplayName)'"
                        Write-Host ""
                        $params = @{
                            "extensionAttributes" = @{
                                #Attribute check for if this is a new CloudPC
                                "$ExstensionAttributeKey" = "$ExstensionAttributeValue"
                            }
                        }

                        Update-MgDevice -DeviceId $CPCDeviceInfo.Id -BodyParameter ($params | ConvertTo-Json)

                    } catch {
                        write-output "Unable to set Attribute on AzureAD Device:'$CPCDeviceInfo.DisplayName'" | out-host
                        write-output $_.Exception.Message | out-host
                        break

                    }
                }
            }

            catch {
                write-output "Unable to get Cloud PC Device status in Endpoint Manager" | out-host
                write-output $_.Exception.Message | out-host
                break
            }
        } else {
            Write-Output " The Attribute is already been configured to this $($CPCDeviceInfo.DisplayName) Machine... "
        }
    }
}
# Connect-MgGraph -Scopes "CloudPC.Read.All", "User.Read.all", "Directory.ReadWrite.All", "Mail.Send", "Device.Read.All", "Directory.AccessAsUser.All"
