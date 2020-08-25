##############################################################
# Variables
##############################################################

# Get existing context
$currentAzContext = Get-AzContext

# Get your current subscription ID. 
$subscriptionID=$currentAzContext.Subscription.Id

# Destination image resource group
$imageResourceGroup="AIBrg-rcctest"

# Location
$location="eastus"

# Image distribution metadata reference name
$runOutputName="aibCustWin10ManImgWVD"

# Image template name
$imageTemplateName="WVDimageR01"

# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$runOutputName="wvdclientR01"

# Create a resource group for Image Template and Shared Image Gallery
New-AzResourceGroup -Name $imageResourceGroup -Location $location

Start-Sleep -Seconds 30

# setup role def names, these need to be unique
$timeInt=$(get-date -UFormat "%s")
$imageRoleDefName="Azure Image Builder Image Def"+$timeInt
$identityName="aibIdentity"+$timeInt

## Add AZ PS module to support AzUserAssignedIdentity
Install-Module -Name Az.ManagedServiceIdentity

# create identity
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName

$identityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).Id
$identityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $identityName).PrincipalId

Start-Sleep -Seconds 30

$aibRoleImageCreationUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"

# download config
Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

# create role definition
New-AzRoleDefinition -InputFile $aibRoleImageCreationPath

# grant role definition to image builder service principal
New-AzRoleAssignment -ObjectId $identityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"

### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve:
# https://docs.microsoft.com/azure/role-based-access-control/troubleshooting

# Image gallery name
$sigGalleryName= "AIBGallery"

# Image definition name
$imageDefName ="win10entpersonalimage"

# additional replication region
# $BNPreplRegion2="eastus"

# Create the gallery
New-AzGallery `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup  `
   -Location $location

# Create the image definition
New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $imageResourceGroup `
   -Location $location `
   -Name $imageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'MicrosoftWindowsDesktop' `
   -Offer 'windows-10' `
   -Sku '19h2-ent'


##############################################################
# Download and configure the template
##############################################################

$templateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest `
   -Uri "https://github.com/virtualosityinc/DevanteAzureAIB/blob/master/armTemplateWinSIG.json" `
   -OutFile $templateFilePath `
   -UseBasicParsing

(Get-Content -path $templateFilePath -Raw ) `
   -replace '<subscriptionID>',$subscriptionID | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<rgName>',$imageResourceGroup | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<runOutputName>',$runOutputName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<imageDefName>',$imageDefName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<sharedImageGalName>',$sigGalleryName | Set-Content -Path $templateFilePath
(Get-Content -path $templateFilePath -Raw ) `
   -replace '<region1>',$location | Set-Content -Path $templateFilePath
<# (Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<region2>',$BNPreplRegion2 | Set-Content -Path $BNPtemplateFilePath #>
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$identityNameResourceId) | Set-Content -Path $templateFilePath

Start-Sleep -Seconds 15

###########################################################
# Create Image version
###########################################################

New-AzResourceGroupDeployment -ResourceGroupName AIBrg-rcctest -TemplateFile armTemplateWinSIG.json -apiversion "2020-08-13-preview" -imageTemplateName WVDimageR01 -svclocation eastus

Start-Sleep -Seconds 15


###########################################################
# Build Image
###########################################################

Invoke-AzResourceAction `
   -ResourceName $imageTemplateName `
   -ResourceGroupName $imageResourceGroup `
   -ResourceType Microsoft.VirtualMachineImages/imageTemplates `
   -ApiVersion "2020-08-13-preview" `
   -Action Run

Start-Sleep 1800 -Seconds

############################################################
# Create the VM
<############################################################

$imageVersion = Get-AzGalleryImageVersion `
   -ResourceGroupName $imageResourceGroup `
   -GalleryName $sigGalleryName `
   -GalleryImageDefinitionName $imageDefName
   #>