# Cloud-based Render Environment on Azure using Terraform
![capture3](https://user-images.githubusercontent.com/15788466/39260603-d8d192ae-486e-11e8-9759-c7793bd4be02.PNG)

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

