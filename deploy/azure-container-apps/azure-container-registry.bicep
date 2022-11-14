@description('A unique suffix for names')
param appNamePrefix string ='shoppingapp'
param location string = resourceGroup().location

// Azure Container Registry
@description('Provide a globally unique name of your Azure Container Registry')
var acrName = 'acr${appNamePrefix}'
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

output acrUrl string = acr.properties.loginServer
// This is a critical security issue. It is for demo purposes only!
#disable-next-line outputs-should-not-contain-secrets
output acrLogin string = acr.listCredentials().username
// This is a critical security issue. It is for demo purposes only!
#disable-next-line outputs-should-not-contain-secrets
output acrPassword string = acr.listCredentials().passwords[0].value