/*
Runme script below
-New-AzResourceGroupDeployment -TemplateFile main.bicep -location centralus
-Production below will add Audit and storage account
-New-AzResourceGroupDeployment -TemplateFile main.bicep -environmentName Production -location centralus
-ResourceGroupName: TECHSN-IT-DP-RG-DEV-CUS-001
-sqlServerAdministratorLogin:techsn_sqlserveradmin
-sqlServerAdministratorLoginPassword:  Wel2Jun

*/
@description('The Azure region into which the resources should be deployed.')
param location string

@description('The Sql Server Name prefix.')
param SqlServerPrefix string = 'Tecshn-SQLSRVR-01-'
//yry this next time ---> sqlsvr-location-01
@description('The Sql Database Name prefix.')
param MySqlDBName string = 'Tecshn-SQLSRVR-DB01-'
//sqldb-location-01

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

@description('The name and tier of the SQL database SKU.')
param sqlDatabaseSku object = {
  name: 'Standard'
  tier: 'Standard'
}

@description('The name of the environment. This must be Development or Production.')
@allowed([
  'Development'
  'Production'
])
param environmentName string = 'Development'

@description('The name of the audit storage account SKU.')
param auditStorageAccountSkuName string = 'Standard_LRS'

//var sqlServerName = 'teddy${location}${uniqueString(resourceGroup().id)}'
var sqlServerName = '${toLower(SqlServerPrefix)}${location}${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = toLower(MySqlDBName)
var auditingEnabled = environmentName == 'Production'
var auditStorageAccountName = '${take('bearaudit${location}${uniqueString(resourceGroup().id)}', 24)}'

resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: sqlDatabaseSku
}

resource auditStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = if (auditingEnabled) {
  name: auditStorageAccountName
  location: location
  sku: {
    name: auditStorageAccountSkuName
  }
  kind: 'StorageV2'  
}

resource sqlServerAudit 'Microsoft.Sql/servers/auditingSettings@2020-11-01-preview' = if (auditingEnabled) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    storageEndpoint: environmentName == 'Production' ? auditStorageAccount.properties.primaryEndpoints.blob : ''
    storageAccountAccessKey: environmentName == 'Production' ? listKeys(auditStorageAccount.id, auditStorageAccount.apiVersion).keys[0].value : ''
  }
}

output serverName string = sqlServer.name
output location string = location
output serverFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName