# output "azs" {
#   value = join(",", local.azs)
# }

# output "id" {
#   value = module.vpc.vpc_id
# }
#
# output "igw_id" {
#   value = module.vpc.igw_id
# }
#
# output "public_subnets" {
#   # value = join(",", [for subnet in aws_subnet.public : subnet.id])
#   value = module.vpc.private_subnets
# }
#
# output "private_subnets" {
#   # value = join(",", [for subnet in aws_subnet.private : subnet.id])
#   value = module.vpc.public_subnets
# }

output "azs" {
  value = join(",", local.azs)
}

output "id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = join(",", [for subnet in aws_subnet.public : subnet.id])
}

output "private_subnets" {
  value = join(",", [for subnet in aws_subnet.private : subnet.id])
}

output "private_sg" {
  value = aws_security_group.private_sg.id
}

output "public_sg" {
  value = aws_security_group.public_sg.id
}
