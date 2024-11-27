locals {
  azs = sort(var.azs)
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment
  cidr = var.vpc_cidr_block

  azs             = local.azs
  private_subnets = var.private_cidr
  public_subnets  = var.public_cidr

  enable_dns_hostnames = true

  # One NAT Gateway per subnet
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  tags = var.tags
}
