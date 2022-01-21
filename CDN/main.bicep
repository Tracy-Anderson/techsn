
/* Runme script
New-AzResourceGroupDeployment -TemplateFile main.bicep
*/
@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name of the App Service app.')
param appServiceAppName string = 'techsn-${uniqueString(resourceGroup().id)}'

@description('The name of the App Service plan SKU.')
param appServicePlanSkuName string = 'F1'

@description('Indicates whether a CDN should be deployed.')
param deployCdn bool = true

var appServicePlanName = 'techsn-product-launch-plan'

module app 'modules/app.bicep' = {
  name: 'techsn-launch-app'
  params: {
    appServiceAppName: appServiceAppName 
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
    location: location
  }
}
module cdn 'modules/cdn.bicep' = if (deployCdn) {
  name: 'techsn-launch-cdn'
  params: {
    httpsOnly: true
    originHostName: app.outputs.appServiceAppHostName
  }
}

@description('The host name to use to access the website.')
//output websiteHostName string = app.outputs.appServiceAppHostName
output websiteHostName string = deployCdn ? cdn.outputs.endpointHostName : app.outputs.appServiceAppHostName
