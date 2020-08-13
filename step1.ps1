# Get existing context
$currentBNPAzContext = Get-AzContext

# Get your current subscription ID. 
$BNPsubscriptionID=$currentBNPAzContext.Subscription.Id

# Destination image resource group
$BNPimageResourceGroup="AIBrg-rcctest"

# Location
$BNPlocation="eastus"

# Image distribution metadata reference name
$BNPrunOutputName="BNPaibCustWin10ManImgWVD"

# Image template name
$imageTemplateName="WVDimageR01"

# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$BNPrunOutputName="BNPwvdclientR01"

# Create a resource group for Image Template and Shared Image Gallery
New-AzResourceGroup -Name $BNPimageResourceGroup -Location $BNPlocation

Start-Sleep -Seconds 30

# setup role def names, these need to be unique
$BNPtimeInt=$(get-date -UFormat "%s")
$BNPimageRoleDefName="Azure Image Builder Image Def"+$BNPtimeInt
$BNPidentityName="aibIdentity"+$BNPtimeInt

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $BNPimageResourceGroup -Name $BNPidentityName

$BNPidentityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $BNPimageResourceGroup -Name $BNPidentityName).Id
$BNPidentityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $BNPimageResourceGroup -Name $BNPidentityName).PrincipalId

Start-Sleep -Seconds 30

$BNPaibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$BNPaibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $BNPaibRoleImageCreationUrl -OutFile $BNPaibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $BNPaibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$BNPsubscriptionID) | Set-Content -Path $BNPaibRoleImageCreationPath
((Get-Content -path $BNPaibRoleImageCreationPath -Raw) -replace '<rgName>', $BNPimageResourceGroup) | Set-Content -Path $BNPaibRoleImageCreationPath
((Get-Content -path $BNPaibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $BNPimageRoleDefName) | Set-Content -Path $BNPaibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile $BNPaibRoleImageCreationPath

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $BNPidentityNamePrincipalId -RoleDefinitionName $BNPimageRoleDefName -Scope "/subscriptions/$BNPsubscriptionID/resourceGroups/$BNPimageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
# https://docs.microsoft.com/azure/role-based-access-control/troubleshooting