# Terraform AWS VPC Module

This repository contains a reusable, flexible, and production-ready Terraform module for provisioning a multi-tier VPC on AWS. The module is designed with best practices to create a secure and scalable network foundation for any cloud-native application.

## Key Features

*   **Multi-AZ Architecture:** Deploys resources across two Availability Zones for high availability and fault tolerance.
*   **Three-Tier Subnetting:** Creates distinct public, private, and database subnets to logically and securely segment application components.
*   **Secure Egress Traffic:** Implements a NAT Gateway in the public subnet to provide secure, one-way internet access for services running in the private and database subnets.
*   **Fully Customizable:** Exposes a rich set of input variables to allow users to easily configure CIDR blocks, tags, and other parameters.
*   **Well-Defined Outputs:** Provides clear outputs for all critical resource IDs (VPC ID, subnet IDs), enabling seamless integration with other Terraform modules (e.g., for deploying EC2 instances or RDS).

---

## Technology Showcase

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/Amazon_AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)

---

## Architectural Diagram

This module provisions the following architecture:

*   A central **VPC** to provide a logically isolated network environment.
*   An **Internet Gateway (IGW)** attached to the VPC to allow communication with the internet.
*   **Public Subnets** in each AZ with a route table pointing to the IGW, for placing public-facing resources like load balancers or web servers.
*   **Private Subnets** in each AZ for backend application servers.
*   **Database Subnets** in each AZ for data persistence layers like RDS.
*   An **EIP** and **NAT Gateway** located in one of the public subnets.
*   Separate **Route Tables** for the private and database tiers, routing all outbound traffic through the NAT Gateway. This allows backend resources to access the internet (e.g., for software updates) without being directly exposed to inbound traffic.
*   A **DB Subnet Group** that bundles the database subnets, required for services like Amazon RDS.

![VPC Architecture Diagram](<link-to-your-custom-vpc-diagram.png>)  
*It is highly recommended to create a custom diagram visualizing this structure and place it in an `assets` folder.*

---

## How to Use This Module

This module is designed to be consumed by other Terraform configurations. A complete working example is provided in the `/example` directory.

### Example Configuration (`/example/vpc.tf`)

To use this module, you define a `module` block in your Terraform code and provide it with the required variables.

```terraform
# Required providers and backend configuration
provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    # ... your backend configuration ...
  }
}

# --- Module Declaration ---
module "vpc" {
  source = "git::https://github.com/Sarthakx67/terraform-aws-vpc-module.git"

  # --- Required Input Variables ---
  project_name = "my-application"
  cidr_block   = "10.0.0.0/16"
  public_subnet_cidr_block = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidr_block = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidr_block = ["10.0.21.0/24", "10.0.22.0/24"]

  # --- Optional Input Variables ---
  common_tags = {
    Environment = "DEV"
    Terraform   = "true"
  }
}
```

### Execution Steps

1.  Navigate to the directory containing your configuration (e.g., the `/example` folder).
2.  Initialize the Terraform providers and backend: `terraform init`
3.  Generate an execution plan to see what will be created: `terraform plan`
4.  Apply the configuration to provision the resources on AWS: `terraform apply`

---

## Module Reference

### Input Variables

| Name                            | Description                                                 | Type       | Default | Required |
|---------------------------------|-------------------------------------------------------------|------------|:-------:|:--------:|
| `project_name`                  | A name for the project, used to prefix resource names.        | `string`   | n/a     |   yes    |
| `cidr_block`                    | The primary CIDR block for the entire VPC.                     | `string`   | n/a     |   yes    |
| `public_subnet_cidr_block`      | A list of two CIDR blocks for the public subnets.           | `list(string)` | n/a     |   yes    |
| `private_subnet_cidr_block`     | A list of two CIDR blocks for the private subnets.          | `list(string)` | n/a     |   yes    |
| `database_subnet_cidr_block`    | A list of two CIDR blocks for the database subnets.         | `list(string)` | n/a     |   yes    |
| `enable_dns_hostnames`          | Enables DNS hostnames in the VPC.                                | `bool`     | `true`  |    no    |
| `enable_dns_support`            | Enables DNS support in the VPC.                                  | `bool`     | `true`  |    no    |
| `common_tags`                   | A map of common tags to apply to all resources.                 | `map(string)` | `{}`    |    no    |
| `vpc_tags`                      | Additional tags to apply specifically to the VPC resource.    | `map(string)` | `{}`    |    no    |
| `igw_tags`                      | Additional tags for the Internet Gateway.                      | `map(string)` | `{}`    |    no    |
| `nat_gateway_tags`              | Additional tags for the NAT Gateway.                           | `map(string)` | `{}`    |    no    |
| `public_route_table_tags`       | Additional tags for the public route table.                     | `map(string)` | `{}`    |    no    |
| `private_route_table_tags`      | Additional tags for the private route table.                    | `map(string)` | `{}`    |    no    |
| `database_route_table_tags`     | Additional tags for the database route table.                   | `map(string)` | `{}`    |    no    |
| `db_subnet_group_tags`          | Additional tags for the DB Subnet Group.                         | `map(string)` | `{}`    |    no    |


### Outputs

| Name                   | Description                                  |
|------------------------|----------------------------------------------|
| `vpc_id`               | The ID of the newly created VPC.              |
| `public_subnet_ids`    | A list of the IDs of the public subnets.      |
| `private_subnet_ids`   | A list of the IDs of the private subnets.     |
| `database_subnet_ids`  | A list of the IDs of the database subnets.    |