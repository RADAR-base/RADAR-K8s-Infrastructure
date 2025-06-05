# Syncing radda-base Image to Azure Container Registry

This document explains how to sync the radda-base image from other container registries to Azure Container Registry (ACR).

## Prerequisites

1. Azure CLI installed
2. Logged into Azure (`az login`)
3. Have an Azure Container Registry instance
4. Have access to the source image registry

## Sync Steps

1. Login to Azure Container Registry:
```bash
az acr login --name <your-acr-name>
```

2. Pull radda-base image from source registry:
```bash
docker pull <source-registry>/radda-base:<tag>
```

3. Tag the image for ACR:
```bash
docker tag <source-registry>/radda-base:<tag> <your-acr-name>.azurecr.io/radda-base:<tag>
```

4. Push the image to ACR:
```bash
docker push <your-acr-name>.azurecr.io/radda-base:<tag>
```

## Using Azure CLI Direct Import

Alternatively, you can import the image directly from the source registry using Azure CLI:

```bash
az acr import \
  --name <your-acr-name> \
  --source <source-registry>/radda-base:<tag> \
  --image radda-base:<tag>
```

## Verification

After importing, you can verify the successful sync using:

```bash
az acr repository show-tags --name <your-acr-name> --repository radda-base
```

## Notes

1. Ensure sufficient network bandwidth for image transfer
2. If the image is large, the sync process may take some time
3. Check ACR storage quota before syncing
4. If using a private registry as source, ensure authentication is properly configured
