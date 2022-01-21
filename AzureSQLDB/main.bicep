/* Deploy multiple Instances of SQLServer/DBs
Runme script below
-New-AzResourceGroupDeployment -TemplateFile main.bicep -location centralus
-Production below will add Audit and storage account
-New-AzResourceGroupDeployment -TemplateFile main.bicep -environmentName Production -location centralus
-ResourceGroupName: TECHSN-IT-DP-RG-DEV-CUS-001
-sqlServerAdministratorLogin:techsn_sqlserveradmin
-sqlServerAdministratorLoginPassword:  Wel2Jun

*/
param projectname string = 'Tecshn-'
/* ----------------------------------------------------------------------
   SqlServer/Database Params
   -----------------------------------------------------------------------
*/
@description('Add Azure regions into which the resources should be deployed.')
param locations array = [
  'centralus'
  'eastus2'
]

@secure()
@description('The administrator login username for the SQL server.')
param sqlServerAdministratorLogin string

@secure()
@description('The administrator login password for the SQL server.')
param sqlServerAdministratorLoginPassword string

/* ----------------------------------------------------------------------
   Virtual Network Params
   -----------------------------------------------------------------------*/
@description('The IP address range for all virtual networks to use.')
param virtualNetworkAddressPrefix string = '10.10.0.0/16'

@description('The name and IP address range for each subnet in the virtual networks.')
param subnets array = [
  {
    name: 'frontend'
    ipAddressRange: '10.10.5.0/24'
  }
  {
    name: 'backend'
    ipAddressRange: '10.10.10.0/24'
  }
]

var subnetProperties = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.ipAddressRange
  }
}]
/* ----------------------------------------------------------------------
   Module Section
   -----------------------------------------------------------------------
*/
module databases 'modules/database.bicep' = [for location in locations: {
  name: 'database-${location}'
  params: {
    location: location
    sqlServerAdministratorLogin: sqlServerAdministratorLogin
    sqlServerAdministratorLoginPassword: sqlServerAdministratorLoginPassword
  }
}]
/*
Note: This example uses the same address space for all the virtual networks. Ordinarily, 
when you create multiple virtual networks, you would give them different address spaces 
in the event that might need to connect them together.
*/
resource virtualNetworks 'Microsoft.Network/virtualNetworks@2020-11-01' = [for location in locations: {
  name: '${toLower(projectname)}${location}'
  location: location
  properties:{
    addressSpace:{
      addressPrefixes:[
        virtualNetworkAddressPrefix
      ]
    }
    subnets: subnetProperties
  }
}]
