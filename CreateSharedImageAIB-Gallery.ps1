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