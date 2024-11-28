locals {
  azs = sort(var.azs)
}

resource "aws_instance" "example" {
  count         = length(var.ec2_instances)
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t3.medium"
  subnet_id     = var.ec2_subnet_id

  cpu_options {
    core_count       = 2
    threads_per_core = 2
  }

  tags = merge(
    { Name = var.environment },
    var.tags
  )
}
