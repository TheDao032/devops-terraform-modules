locals {
  azs = sort(var.azs)
  public_ec2_instances = [
    {
      instance_type    = "t3.medium"
      core_count       = 1
      threads_per_core = 2
    },
    {
      instance_type    = "t3.medium"
      core_count       = 1
      threads_per_core = 2
    },
  ]

  # private_ec2_instances = [
  #   {
  #     instance_type    = "t3.medium"
  #     core_count       = 1
  #     threads_per_core = 2
  #   },
  # ]
}

resource "aws_key_pair" "k3s_cluster" {
  key_name   = var.key_pair
  public_key = var.ssh_public_key
}

resource "aws_instance" "public_instances" {
  count                       = length(local.public_ec2_instances)
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = local.public_ec2_instances[count.index].instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_sg_id]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.key_pair

  cpu_options {
    core_count       = local.public_ec2_instances[count.index].core_count
    threads_per_core = local.public_ec2_instances[count.index].threads_per_core
  }

  tags = merge(
    { Name = "public-ec2-${var.environment}-${count.index}" },
    var.tags
  )
}

# resource "aws_instance" "private_instances" {
#   count                  = length(local.private_ec2_instances)
#   ami                    = data.aws_ami.amazon_linux_2023.id
#   instance_type          = local.private_ec2_instances[count.index].instance_type
#   subnet_id              = var.private_subnet_id
#   vpc_security_group_ids = [var.private_sg_id]
#   key_name               = var.key_pair
#
#   cpu_options {
#     core_count       = local.private_ec2_instances[count.index].core_count
#     threads_per_core = local.private_ec2_instances[count.index].threads_per_core
#   }
#
#   tags = merge(
#     { Name = "private-ec2-${var.environment}-${count.index}" },
#     var.tags
#   )
# }
