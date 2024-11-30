locals {
  azs = sort(var.azs)
  ec2_instances = [
    {
      subnet_id        = var.subnet_id
      instance_type    = "t3.medium"
      core_count       = 1
      threads_per_core = 2
    },
    # {
    #   subnet_id        = var.subnet_id
    #   instance_type    = "t3.medium"
    #   core_count       = 1
    #   threads_per_core = 2
    # },
    # {
    #   subnet_id        = var.subnet_id
    #   instance_type    = "t3.medium"
    #   core_count       = 1
    #   threads_per_core = 2
    # }
  ]
}

resource "aws_instance" "main" {
  count         = length(local.ec2_instances)
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = local.ec2_instances[count.index].instance_type
  subnet_id     = local.ec2_instances[count.index].subnet_id

  cpu_options {
    core_count       = local.ec2_instances[count.index].core_count
    threads_per_core = local.ec2_instances[count.index].threads_per_core
  }

  tags = merge(
    { Name = var.environment },
    var.tags
  )
}
