@description('A unique suffix for names')
param nameSuffix string = 'd1'
param appNamePrefix string ='shoppingapp'
param location string = resourceGroup().location

// Azure Container Registry
@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${appNamePrefix}${nameSuffix}'
var tags = {
  Purpose: 'Azure Workshop'
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}
