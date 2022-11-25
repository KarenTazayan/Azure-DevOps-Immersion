@description('A suffix for resource names uniqueness.')
param nameSuffix string = 'd1'
param appNamePrefix string ='shoppingapp'
param semVer string = 'latest'
param location string = resourceGroup().location
param executorSecurityPrincipal string

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
var sigrName='sigr-${appNamePrefix}-${nameSuffix}'
var keyVaultName = 'kv-${appNamePrefix}-${nameSuffix}'
var webUiStorageName = 'stwebui${appNamePrefix}${nameSuffix}'
var webUiStorageBlobContainerName = 'web-ui-data-protection'
var webUiCtapName = 'ctap-${appNamePrefix}-ui-${nameSuffix}'
var webUiCtapEnvName = 'ctapenv-${appNamePrefix}-ui-${nameSuffix}'

var tags = {
  Purpose: 'Azure Workshop'
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: executorSecurityPrincipal
        permissions: {
          keys: [
            'create'
          ]
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

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // TODO: Change scope to be more granular. 
  scope: keyVault
  name: guid(keyVaultName)
  properties: {
    // Owner
    // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
    principalId: executorSecurityPrincipal
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultKey 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyVault
  name: 'WebUIDataProtectionKey'
  properties: {
    kty: 'RSA'
    keySize: 3072
  }
  dependsOn: [
    keyVaultRoleAssignment
  ]
}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webUiCtap.identity.principalId
        permissions: {
          keys: [
            'get'
            'decrypt'
            'encrypt'
            'unwrapKey'
            'wrapKey'
            'verify'
            'sign'
          ]
        }
      }
    ]
  }
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

resource webUiStorage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: webUiStorageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource webUiStorageBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  name: '${webUiStorage.name}/default/${webUiStorageBlobContainerName}'
  properties: {
  }
}

resource web 'Microsoft.Authorization/roleAssignments@2022-04-01' = { 
  scope: webUiStorage
  name: guid(webUiStorageName)
  properties: {
    // Contributor
    // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: webUiCtap.identity.principalId
    principalType: 'ServicePrincipal'
  }
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

resource signalR 'Microsoft.SignalRService/signalR@2022-02-01' = {
  name: sigrName
  location: location
  sku: {
    capacity: 1
    name: 'Free_F1'
  }
  kind: 'SignalR'
  properties: {
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
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
                name: 'AZURE_SIGNALR_CONNECTION_STRING'
                value: signalR.listKeys().primaryConnectionString
            }
            {
              name: 'APPINSIGHTS_CONNECTION_STRING'
              value: reference(appi.id, '2020-02-02').ConnectionString
            }
            {
              name: 'AZURE_BLOB_STORAGE_FOR_WEB_UI_URI'
              value: '${webUiStorage.properties.primaryEndpoints.blob}${webUiStorageBlobContainerName}/keys.xml'
            }
            {
              name: 'AZURE_KEY_VAULT_FOR_WEB_UI_URI'
              value: '${keyVault.properties.vaultUri}keys/WebUIDataProtectionKey/'
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

output fullReferenceOutput object = keyVault.properties
