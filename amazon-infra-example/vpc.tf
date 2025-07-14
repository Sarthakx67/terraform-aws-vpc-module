module "vpc" {
  source = "git::https://github.com/Sarthakx67/terraform-aws-vpc-module.git"
  project_name = var.project_name
#   variables.tf
  cidr_block = var.cidr_block 
  common_tags = var.common_tags
  public_subnet_cidr_block = var.public_subnet_cidr_block
  private_subnet_cidr_block = var.private_subnet_cidr_block
  database_subnet_cidr_block = var.database_subnet_cidr_block
}
