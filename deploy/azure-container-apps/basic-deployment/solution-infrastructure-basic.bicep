@description('A suffix for resource names uniqueness.')
// d - development b - basic => db
param nameSuffix string = 'db1'
param appNamePrefix string ='shoppingapp'
param semVer string = 'latest'
param location string = resourceGroup().location

// Azure SQL
param sqlAdministratorLogin string = 'sq'
@secure()
param sqlAdministratorPassword string

// Azure Container Registry
param acrUrl string
@secure()
param acrLogin string
@secure()
param acrPassword string

// General
var vnetName = 'vnet-${appNamePrefix}-${nameSuffix}'
var revisionSuffix = 'v${replace(semVer, '.', '-')}'
var appiName = 'appi-${appNamePrefix}-${nameSuffix}'
var logName = 'log-${appNamePrefix}-${nameSuffix}'

// Microsoft Orleans Hosting
var storageName = 'st${appNamePrefix}${nameSuffix}'
var sqlName = 'sql-${appNamePrefix}-${nameSuffix}'
var siloHostCtapName = 'ctap-${appNamePrefix}-${nameSuffix}'
var siloHostCtapEnvName = 'ctapenv-${appNamePrefix}-${nameSuffix}'

// Web UI Hosting
var webUiCtapName = 'ctap-${appNamePrefix}-ui-${nameSuffix}'
var webUiCtapEnvName = 'ctapenv-${appNamePrefix}-ui-${nameSuffix}'

var tags = {
  Purpose: 'Azure Workshop'
}

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
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
          value: acrPassword
        }
      ]
      registries: [
        {
          server: acrUrl
          username: acrLogin
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      revisionSuffix: revisionSuffix
      containers: [
        {
          image: '${acrUrl}/shoppingapp/silohost:${semVer}'
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
        maxReplicas: 10
      }
    }
  }
}

resource webUiCtap 'Microsoft.App/containerApps@2022-03-01' = {
  name: webUiCtapName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: webUiCtapEnv.id
    configuration: {
      activeRevisionsMode: 'multiple'
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
      registries: [
        {
          server: acrUrl
          username: acrLogin
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      revisionSuffix: revisionSuffix
      containers: [
        {
          image: '${acrUrl}/shoppingapp/webui:${semVer}'
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
        minReplicas: 0
        maxReplicas: 10
      }
    }
  }
}

output fullReferenceOutput object = siloHostCtap.properties
