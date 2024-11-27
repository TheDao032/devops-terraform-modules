locals {
  service_ports = ["22", "80", "443"]
}

resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg"
  description = "EC2 Security Groups"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    { Name = "${var.environment}-ec2-sg" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.ec2.id

  ip_protocol = "-1"
  # from_port   = 0
  # to_port     = 0

  tags = merge(
    { Name = "${var.environment}-ec2-sg-ingress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_ipv4" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  # from_port   = 0
  # to_port     = 0

  tags = merge(
    { Name = "${var.environment}-ec2-sg-egress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_ipv6" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv6   = "::/0"
  ip_protocol = "-1"
  # from_port   = 0
  # to_port     = 0

  tags = merge(
    { Name = "${var.environment}-ec2-sg-egress-rule" },
    var.tags
  )
}
