@echo off

SETLOCAL ENABLEDELAYEDEXPANSION
rem Set values for your subscription and resource group
set unique_id=!random!!random!
set subscription_id=ec4c6185-4c9f-4800-bc8d-059d6420379d
set resource_group=rg-aisearch-demo!unique_id!
set location=eastus
rem Get random numbers to create unique resource names
set storage_name=saaisearchdemo!unique_id!
set aisearch_name=ai-adp-aisearch-demo!unique_id!

echo Creating resource group...
call az group create --name !resource_group! --location !location! --subscription !subscription_id! --output none


echo Creating storage...
call az storage account create --name !storage_name! --subscription !subscription_id! --resource-group !resource_group! --location !location! --sku Standard_LRS --encryption-services blob --default-action Allow --output none

rem Hack to get storage key
for /f "tokens=*" %%a in ( 
'az storage account keys list --subscription !subscription_id! --resource-group !resource_group! --account-name !storage_name! --query "[?keyName=='key1'].{keyName:keyName, permissions:permissions, value:value}"' 
) do ( 
set key_json=!key_json!%%a 
) 

echo Creating container and uploading files...
set key_string=!key_json:[ { "keyName": "key1", "permissions": "Full", "value": "=!
set AZURE_STORAGE_KEY=!key_string:" } ]=!

call az storage container create --account-name !storage_name! --name hrdocs --account-key %AZURE_STORAGE_KEY% --output none
echo Creating azure ai services account...
call az cognitiveservices account create --kind CognitiveServices --location !location! --name !aisearch_name! --sku S0 --subscription !subscription_id! --resource-group !resource_group! --yes --output none

echo Creating search service...
echo (If this gets stuck at '- Running ..' for more than a minute, press CTRL+C then select N)
call az search service create --name !aisearch_name! --subscription !subscription_id! --resource-group !resource_group! --location !location! --sku basic --output none
call az storage account show-connection-string --subscription !subscription_id! --resource-group !resource_group! --name !storage_name! --output none
call az cognitiveservices account keys list --subscription !subscription_id! --resource-group !resource_group! --name !aisearch_name! --output none

echo  Url: https://!aisearch_name!.search.windows.net
echo  Admin Keys:
call az search admin-key show --subscription !subscription_id! --resource-group !resource_group! --service-name !aisearch_name!
echo  Query Keys:
call az search query-key list --subscription !subscription_id! --resource-group !resource_group! --service-name !aisearch_name!
pause
echo Uploading files...



@rem set current directory to the directory of this script
cd %~dp0
echo %cd%

call az storage blob upload-batch --account-name !storage_name! --auth-mode key --account-key %AZURE_STORAGE_KEY% -d hrdocs -s data-dump


pause