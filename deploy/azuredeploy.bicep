@description('A unique suffix for names')
param nameSuffix string = 't1'
param appNamePrefix string ='shopping-app'
param location string = resourceGroup().location
param sqlAdministratorLogin string = 'sq'
@secure()
param sqlAdministratorPassword string

var appiName = 'appi-shopping-app-${nameSuffix}'
var planName = 'plan-shopping-app-${nameSuffix}'
var uiPlanName = 'plan-shopping-app-ui-${nameSuffix}'
var keyVaultName = 'kv-shopping-app-${nameSuffix}'
var logName = 'log-shopping-app-${nameSuffix}'
var storageName = 'stshoppingapp${nameSuffix}'
var vnetName = 'vnet-${appNamePrefix}-${nameSuffix}'
var appWebUIName = '${appNamePrefix}-webui-${nameSuffix}'
var appSiloHostName = '${appNamePrefix}-silohost-${nameSuffix}'
var sqlName = 'sql-${appNamePrefix}-${nameSuffix}'
var tags = {
  Purpose: 'Azure Workshop'
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: reference(appShoppingAppWebUI.id, '2020-06-01', 'full').identity.principalId
        permissions: {
          keys: [
            'get'
            'create'
            'decrypt'
            'encrypt'
          ]
          secrets: [
            'get'
            'set'
          ]
          certificates: []
        }
      }
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
          addressPrefix: '10.0.0.0/24'
          delegations: [ 
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'WebUI'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [ 
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource planShoppingAppUi 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: uiPlanName
  location: location
  tags: tags
  kind: 'app'
  sku: {
    name: 'B1'
  }
}

resource planShoppingAppSilo 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'app'
  sku: {
    name: 'S1'
    capacity: 1
  }
}

resource appShoppingAppWebUI 'Microsoft.Web/sites@2021-03-01' = {
  name: appWebUIName
  location: location
  tags: tags
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: planShoppingAppUi.id
    virtualNetworkSubnetId: vnet.properties.subnets[1].id
    siteConfig: {
      alwaysOn: true
      webSocketsEnabled: true
      appSettings: [
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'APPINSIGHTS_CONNECTION_STRING'
          value: reference(appi.id, '2020-02-02').ConnectionString
        }
      ]
      netFrameworkVersion: 'v6.0'
    }
  }
}

resource appShoppingAppWebUIConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${appShoppingAppWebUI.name}/metadata'
  properties: {
    CURRENT_STACK: 'dotnet'
  }
}

resource appShoppingAppSiloHost 'Microsoft.Web/sites@2021-03-01' = {
  name: appSiloHostName
  location: location
  tags: tags
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: planShoppingAppSilo.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      alwaysOn: true
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      appSettings: [
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
      netFrameworkVersion: 'v6.0'
    }
  }
}

resource appShoppingAppSiloHostConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  name: '${appShoppingAppSiloHost.name}/metadata'
  properties: {
    CURRENT_STACK: 'dotnet'
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

output fullReferenceOutput object = keyVault.properties
