/*
Notes:
--helpful link
https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/template-specs?tabs=azure-powershell
-- view all template specs in your subscription by using:
Get-AzTemplateSpec   
--view details of a template spec, including its versions with:
Get-AzTemplateSpec -ResourceGroupName templateSpecsRG -Name storageSpec --

*/

param templateSpecName string = 'CreateStorageAccount'
param templateSpecVersionName string = '0.1'
param location string = resourceGroup().location

resource createTemplateSpec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: templateSpecName
  location: location
  properties: {
    description: 'A basic templateSpec - creates a storage account.'
    displayName: 'Storage account (Standard_LRS)'
  }
}

resource createTemplateSpecVersion 'Microsoft.Resources/templateSpecs/versions@2021-05-01' = {
  parent: createTemplateSpec
  name: templateSpecVersionName
  location: location
  properties: {
    //Start Main json Template -----------------------------------------------------------
    mainTemplate: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        storageAccountType: {
          type: 'string'
          defaultValue: 'Standard_LRS'
          allowedValues: [
            'Standard_LRS'
            'Standard_GRS'
            'Standard_ZRS'
            'Premium_LRS'
          ]
        }
      }
      resources: [
        {
          type: 'Microsoft.Storage/storageAccounts'
          apiVersion: '2019-06-01'
          name: 'store$uniquestring(resourceGroup().id)'
          location: resourceGroup().location
          kind: 'StorageV2'
          sku: {
            'name': '[parameters(\'storageAccountType\')]'
          }
        }
      ]
    }
    //End Main Template -----------------------------------------------------------
  }
}
