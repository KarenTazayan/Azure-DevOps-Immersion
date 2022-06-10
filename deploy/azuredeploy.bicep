@description('A unique suffix for names')
param nameSuffix string = 'a1'
param appNamePrefix string ='shopping-app'
param location string = resourceGroup().location
param sqlAdministratorLogin string = 'sq'
param sqlAdministratorLoginPassword string = 'Passw@rd1+'

var appiName = 'appi-shopping-app-${nameSuffix}'
var planName = 'plan-shopping-app-${nameSuffix}'
var keyVaultName = 'kv-shopping-app-${nameSuffix}'
var logName = 'log-shopping-app-${nameSuffix}'
var storageName = 'stshoppingapp${nameSuffix}'
var vnetName = 'vnet-${appNamePrefix}-${nameSuffix}'
var appWebUIName = '${appNamePrefix}-webui-${nameSuffix}'
var appSiloHostName = '${appNamePrefix}-silohost-${nameSuffix}'
var sqlName = 'sql-account-search-${nameSuffix}'

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
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
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  location: location
}

resource log 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource appi 'microsoft.insights/components@2020-02-02-preview' = {
  name: appiName
  location: location
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
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
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
    ]
  }
}

resource planShoppingApp 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: planName
  location: location
  kind: 'app'
  sku: {
    name: 'S1'
  }
}

resource appShoppingAppWebUI 'Microsoft.Web/sites@2021-03-01' = {
  name: appWebUIName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: planShoppingApp.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      alwaysOn: true
      webSocketsEnabled: true
      appSettings: [
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${appiName}', '2020-02-02-preview').InstrumentationKey
        }
      ]
      netFrameworkVersion: 'v6.0'
    }
  }
}

resource appShoppingAppSiloHost 'Microsoft.Web/sites@2021-03-01' = {
  name: appSiloHostName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: planShoppingApp.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      alwaysOn: true
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      appSettings: [
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(resourceId(resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageName), '2019-04-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${appiName}', '2020-02-02-preview').InstrumentationKey
        }
      ]
      netFrameworkVersion: 'v6.0'
    }
  }
}

resource sql 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: sqlName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
  }
}

resource sql_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  parent: sql
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sql_MicrosoftAccounts 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sql
  name: 'MicrosoftAccounts'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

output fullReferenceOutput object = keyVault.properties
