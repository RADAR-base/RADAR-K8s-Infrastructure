# Azure Terraform Functionality

This project uses Terraform to automate the deployment of Azure resources, including resource groups, virtual networks, subnets, Azure Kubernetes Service (AKS), Azure Container Registry (ACR), and PostgreSQL Flexible Server.

## Directory Structure

```
azure/
├── main.tf          # Main configuration file, defining resource groups and module references
├── provider.tf      # Provider configuration (azurerm, kubernetes, local)
├── variables.tf     # Global variable definitions
├── outputs.tf       # Global output definitions
├── network/         # Network module
│   ├── main.tf      # Virtual network and subnet configuration
│   ├── variables.tf # Network module variable definitions
│   └── outputs.tf   # Network module output definitions
├── kubernetes/      # Kubernetes module
│   ├── main.tf      # AKS cluster configuration
│   ├── rbac.tf      # Role assignment from AKS to ACR
│   ├── variables.tf # Kubernetes module variable definitions
│   └── outputs.tf   # Kubernetes module output definitions
├── registry/        # Container registry module
│   ├── main.tf      # ACR configuration
│   ├── variables.tf # Container registry module variable definitions
│   └── outputs.tf   # Container registry module output definitions
└── postgresql-flexible-server/  # PostgreSQL Flexible Server module
    ├── main.tf      # PostgreSQL server configuration
    ├── variables.tf # PostgreSQL module variable definitions
    └── outputs.tf   # PostgreSQL module output definitions
```

## Functionality

- **Resource Group**: Creates an Azure resource group to organize all resources.
- **Virtual Network**: Creates a VNet and subnet to provide a network environment for AKS.
- **AKS Cluster**: Deploys Azure Kubernetes Service, configuring default node pools, network policies, and key vault integration.
- **ACR**: Creates an Azure Container Registry for storing and managing container images.
- **Role Assignment**: Assigns the AcrPull role to AKS for ACR, enabling integration between AKS and ACR.
- **PostgreSQL Flexible Server**: Deploys a PostgreSQL 16 server with the following features:
  - Private DNS Zone integration
  - VNet integration
  - Automatic backup enabled
  - High availability configuration
  - Zone redundancy disabled (zone = null)

## Usage

1. **Initialize**: Run the following command in the `azure` directory to initialize the Terraform working directory:
   ```bash
   terraform init
   ```

2. **Plan**: Run the following command to view the resource creation plan:
   ```bash
   terraform plan
   ```

3. **Apply**: Run the following command to create the resources:
   ```bash
   terraform apply
   ```

## Dependencies

- Terraform version >= 1.5.7
- Azure Provider (hashicorp/azurerm) >= 4.28.0
- Kubernetes Provider (hashicorp/kubernetes) >= 2.36.0
- Local Provider (hashicorp/local) >= 2.0.0

## Notes

- This project only manages Azure resources and does not involve local Kubernetes operations.
- If you need to manage Kubernetes resources, generate a kubeconfig via CI/CD or remotely and pass it to the provider.
- All sensitive information (such as ACR passwords, kube_config, and PostgreSQL credentials) is marked as sensitive and will not be displayed in plain text in the output.
- The PostgreSQL server is configured with private networking, so access is only available from within the VNet or through a VPN/Private Link.

## Outputs

- `resource_group_name`: Name of the resource group
- `virtual_network_name`: Name of the virtual network
- `virtual_network_id`: ID of the virtual network
- `subnet_id`: ID of the subnet
- `kubernetes_cluster_name`: Name of the Kubernetes cluster
- `kubernetes_cluster_id`: ID of the Kubernetes cluster
- `kube_config`: Kubernetes configuration (sensitive)
- `container_registry_name`: Name of the container registry
- `container_registry_login_server`: Login server of the container registry
- `container_registry_admin_username`: Admin username of the container registry
- `container_registry_admin_password`: Admin password of the container registry (sensitive)
- `postgresql_fqdn`: The fully qualified domain name of the PostgreSQL server
- `postgresql_instance_id`: The instance ID of the PostgreSQL server
- `postgresql_password`: The administrator password (sensitive)
- `postgresql_username`: The administrator username 