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
$BNPimageTemplateName="VDI-image-testenv-08122020"

# Distribution properties object name (runOutput).
# This gives you the properties of the managed image on completion.
$BNPrunOutputName="BNPwvdclientR01"

# Image gallery name
$BNPsigGalleryName= "BNPAIBG"

# Image definition name
$BNPimageDefName ="win10entpersonalimage"

# additional replication region
# $BNPreplRegion2="eastus"

# setup role def names, these need to be unique
$BNPtimeInt=$(get-date -UFormat "%s")
$BNPimageRoleDefName="Azure Image Builder Image Def"+$BNPtimeInt
$BNPidentityName="aibIdentity"+$BNPtimeInt

# Create the gallery
New-AzGallery `
   -GalleryName $BNPsigGalleryName `
   -ResourceGroupName $BNPimageResourceGroup  `
   -Location $BNPlocation

# Create the image definition
New-AzGalleryImageDefinition `
   -GalleryName $sigGalleryName `
   -ResourceGroupName $BNPimageResourceGroup `
   -Location $BNPlocation `
   -Name $BNPimageDefName `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'BNPRCCTEST' `
   -Offer 'Windows10Enterprise' `
   -Sku '19h2-ent'


##############################################################
# Download and configure the template
##############################################################

$BNPtemplateFilePath = "armTemplateWinSIG.json"

Invoke-WebRequest `
   -Uri "https://github.com/virtualosityinc/DevanteAzureAIB/blob/master/armTemplateWinSIG.json" `
   -OutFile $BNPtemplateFilePath `
   -UseBasicParsing

(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<subscriptionID>',$BNPsubscriptionID | Set-Content -Path $BNPtemplateFilePath
(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<rgName>',$BNPimageResourceGroup | Set-Content -Path $BNPtemplateFilePath
(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<runOutputName>',$BNPrunOutputName | Set-Content -Path $BNPtemplateFilePath
(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<imageDefName>',$BNPimageDefName | Set-Content -Path $BNPtemplateFilePath
(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<sharedImageGalName>',$BNPsigGalleryName | Set-Content -Path $BNPtemplateFilePath
(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<region1>',$BNPlocation | Set-Content -Path $BNPtemplateFilePath
<#(Get-Content -path $BNPtemplateFilePath -Raw ) `
   -replace '<region2>',$BNPreplRegion2 | Set-Content -Path $BNPtemplateFilePath #>
((Get-Content -path $BNPtemplateFilePath -Raw) -replace '<imgBuilderId>',$BNPidentityNameResourceId) | Set-Content -Path $BNPtemplateFilePath