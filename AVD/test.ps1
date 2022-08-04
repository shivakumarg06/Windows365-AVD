git remote set-url origin https://shivakumarg06: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@github.com/shivakumarg06/BicepIaC.git


$ourfilesdata = Get-Content ".\AVD\message.html"
$ourfilesdata.GetType()
# $ourfilesdata | Select-Object { where }

$insert = @()
foreach ( $item in $ourfilesdata) {

}

Add-Content -Path .\AVD\message.html -Stream $name

# Add a new ADS named Secret to the fruits.txt file
Add-Content -Path .\fruits.txt -Stream Secret -Value 'This is a secret. No one should find this.'
Get-Item -Path .\fruits.txt -Stream *


$UserAccount = New-Object PSObject -Property @{
    DisplayName = "Shiva Kumar"
    FirstName   = "Shiva"
    LastName    = "Kumar"

}

$Body = Get-Content '.\AVD\message.html' -Raw

$Expression = "`$OutputBody = `@""`n`r$Body`n`r""`@"
Invoke-Expression $Expression

$OutputBody

$a = Get-MgUser | g
$a.GivenName
$a.Surname


$senderCred = (Get-AzKeyVaultSecret -VaultName $InfraKeyVaultName -Name $VMPWDKey).SecretValue
if ( ! $senderCred) {
    # Undelete deleted Secret if it is recoverable, otherwise new secret cannot be created.
    # New password will be generated though
    if (Get-AzKeyVaultSecret -VaultName $InfraKeyVaultName -Name $VMPWDKey -InRemovedState) {
        Write-Output "Recovering deleted keyvault secret"
        Undo-AzKeyVaultSecretRemoval -VaultName $InfraKeyVaultName -Name $VMPWDKey
        Start-Sleep -Seconds 30       # Resetting Password too quickly results in a conflict error.
    }
}
else {
    Write-Output "The Sender Secret Value doesn't exist, please do verify it..."
}







