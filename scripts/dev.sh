#!/bin/bash

RESOURCE_GROUP_NAME=terraform-state-rg
STAGE_STRG_ACC=tfstagebackend2026
DEV_STRG_ACC=tfdevbackend2026
CONTAINER_NAME=tfstate

# create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus


#create stage storage account 
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STAGE_STRG_ACC --sku Standard_LRS --encryption-services blob

#create dev storage account 
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $DEV_STRG_ACC --sku Standard_LRS --encryption-services blob

# create blob container
az storage container create --name $CONTAINER_NAME --account-name $STAGE_STRG_ACC

# create blob container
az storage container create --name $CONTAINER_NAME --account-name $DEV_STRG_ACC