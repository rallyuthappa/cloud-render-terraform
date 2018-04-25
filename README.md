# Cloud-based Render Environment on Azure using Terraform

This template builds a basic cloud-based rendering solution on Azure. 

The terraform automation scripts creates:
1.	Two Resource Groups
    - Primary resource group for hosting VNets, jump host and other supporting / common resources
    - Secondary resource group for hosting render blades
2.	An Azure virtual network (VNet) with following subnets
    - Render Subnet (for render clients)
    - FastCache Subnet (for Avere vFXTs)
    - Management Subnet (for jump hosts)
    -	Gateway Subnet (for VPN/ExpressRoute connectivity)
3.	Three Network Security Groups with basic rules
4.	A jump host for management / administration / Fast Cache build
5.	A VM Scale Set using the a Ubuntu based custom managed image which takes following inputs:
    - Resource group & location for render clients
    - VM size for Scale Set
    - Capacity – No. of VMs to build
    - Name of the Scale Set
    - Admin user and password

Pre-requisites:
- This template assumes a Azure managed custom image is available within the subscription and in the location requested

Work in Progress:
- Creation of Avere vFXTs 

The template uses a service principal based authentication model. More details here https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html. 

The script require following values as input variables:
- Subscription ID
- Client ID (App ID)
- Client Secret (access key)
- AAD Tenant ID 

Terraform installation and configuration on Azure
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

Note: Terraform is installed by default in the Cloud Shell. By using Cloud Shell, you can skip the install/setup portions of this document.

Terraform on Azure Documentation
https://docs.microsoft.com/en-us/azure/terraform/

