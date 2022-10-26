@description('A unique suffix for names')
param nameSuffix string = 'd1'
param appNamePrefix string ='shoppingapp'
param location string = resourceGroup().location

// Azure SQL
param sqlAdministratorLogin string = 'sq'
@secure()
param sqlAdministratorPassword string

// Azure Container Registry
@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${appNamePrefix}${nameSuffix}'

var appiName = 'appi-${appNamePrefix}-${nameSuffix}'
var keyVaultName = 'kv-${appNamePrefix}-${nameSuffix}'
var logName = 'log-${appNamePrefix}-${nameSuffix}'
var storageName = 'st${appNamePrefix}${nameSuffix}'
var vnetName = 'vnet-${appNamePrefix}-${nameSuffix}'
var sqlName = 'sql-${appNamePrefix}-${nameSuffix}'
var siloHostCtapName = 'ctap-${appNamePrefix}-${nameSuffix}'
var webUiCtapName = 'ctap-${appNamePrefix}-ui-${nameSuffix}'
var siloHostCtapEnvName = 'ctapenv-${appNamePrefix}-${nameSuffix}'
var webUiCtapEnvName = 'ctapenv-${appNamePrefix}-ui-${nameSuffix}'
var tags = {
  Purpose: 'Azure Workshop'
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: [
    ]
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource log 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: appiName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: true
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: log.id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'SiloHost'
        properties: {
          addressPrefix: '10.0.0.0/23'
        }
      }
      {
        name: 'WebUI'
        properties: {
          addressPrefix: '10.0.2.0/23'
        }
      }
    ]
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
  }
}

resource sqlServerAllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlShoppingAppMain 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: 'ShoppingAppMain'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

resource siloHostCtapEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: siloHostCtapEnvName
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: vnet.properties.subnets[0].id
      runtimeSubnetId: vnet.properties.subnets[0].id
    }
    zoneRedundant: false
  }
}

resource webUiCtapEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: webUiCtapEnvName
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: vnet.properties.subnets[1].id
      runtimeSubnetId: vnet.properties.subnets[1].id
    }
    zoneRedundant: false
  }
}

resource siloHostCtap 'Microsoft.App/containerApps@2022-03-01' = {
  name: siloHostCtapName
  location: location
  properties: {
    managedEnvironmentId: siloHostCtapEnv.id
    configuration: {
      activeRevisionsMode: 'multiple'
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          image: '${acr.properties.loginServer}/shoppingappsilohost:latest'
          name: 'silo-host'
          env: [
            {
              name: 'AZURE_SQL_CONNECTION_STRING'
              value: 'Server=tcp:${sqlServer.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlShoppingAppMain.name};Persist Security Info=False;User ID=${sqlAdministratorLogin};Password=${sqlAdministratorPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
            }
            {
              name: 'AZURE_STORAGE_CONNECTION_STRING'
              value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
            }
            {
              name: 'APPINSIGHTS_CONNECTION_STRING'
              value: reference(appi.id, '2020-02-02').ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

resource webUiCtap 'Microsoft.App/containerApps@2022-03-01' = {
  name: webUiCtapName
  location: location
  properties: {
    managedEnvironmentId: webUiCtapEnv.id
    configuration: {
      activeRevisionsMode: 'multiple'
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          image: '${acr.properties.loginServer}/shoppingappwebui:latest'
          name: 'web-ui'
          env: [
            {
              name: 'AZURE_STORAGE_CONNECTION_STRING'
              value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
            }
            {
              name: 'APPINSIGHTS_CONNECTION_STRING'
              value: reference(appi.id, '2020-02-02').ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

output fullReferenceOutput object = keyVault.properties
