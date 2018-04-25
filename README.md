# Cloud-based Render Environment on Azure using Terraform

This template builds a basic cloud-based rendering solution on Azure. 

The terraform automation scripts builds:

1. Two Resource Groups

  a.	Primary resource group for hosting VNets, jump host and other supporting / common resources
  
  b.	Secondary resource group for hosting render blades
2.	An Azure virtual network (VNet) with following subnets
  a.	Render Subnet (for render clients)
  b.	FastCache Subnet (for Avere vFXTs)
  c.	Management Subnet (for jump hosts)
  d.	Gateway Subnet (for VPN/ExpressRoute connectivity)
3.	Three Network Security Groups with basic rules
4.	A jump host for management / administration / Fast Cache build
5.	A VM Scale Set using the a Ubuntu based custom managed image which takes following inputs:
a.	Resource group & location for render clients
b.	VM size for Scale Set
c.	Capacity – No. of VMs to build
d.	Name of the Scale Set
e.	Admin user and password

Pre-requisites:
This template assumes a Azure managed custom image is available within the subscription and in the location requested

Work in Progress:
1.	Creation of Avere vFXTs 
