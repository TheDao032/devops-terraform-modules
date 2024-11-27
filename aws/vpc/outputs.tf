output "azs" {
  value = join(",", local.azs)
}

output "id" {
  value = module.vpc.vpc_id
}

output "igw_id" {
  value = module.vpc.igw_id
}

output "public_subnets" {
  # value = join(",", [for subnet in aws_subnet.public : subnet.id])
  value = module.vpc.private_subnets
}

output "private_subnets" {
  # value = join(",", [for subnet in aws_subnet.private : subnet.id])
  value = module.vpc.public_subnets
}

output "eks_securitygroup" {
  value = aws_security_group.eks.id
}

output "eks_node_securitygroup" {
  value = aws_security_group.eks_node.id
}

output "gateway_securitygroup" {
  value = aws_security_group.gateway.id
}
