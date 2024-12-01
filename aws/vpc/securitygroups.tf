locals {
  service_ports         = ["22", "80", "443"]
  private_service_ports = ["22", "80", "443", "6443"]
}

resource "aws_security_group" "public_sg" {
  name        = "${var.environment}-public-sg"
  description = "EC2 Public Security Groups"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    { Name = "${var.environment}-public-sg" },
    var.tags
  )
}

resource "aws_security_group" "private_sg" {
  name        = "${var.environment}-private-sg"
  description = "EC2 Private Security Groups"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    { Name = "${var.environment}-private-sg" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress_self" {
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.private_sg.id

  ip_protocol = "-1"

  tags = merge(
    { Name = "${var.environment}-private-sg-self-ingress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress" {
  count                        = length(local.private_service_ports)
  security_group_id            = aws_security_group.private_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id

  ip_protocol = "tcp"
  from_port   = tonumber(local.private_service_ports[count.index])
  to_port     = tonumber(local.private_service_ports[count.index])

  tags = merge(
    { Name = "${var.environment}-private-sg-ingress-rule-${count.index}" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "private_egress" {
  security_group_id = aws_security_group.private_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    { Name = "${var.environment}-private-sg-egress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "public_sg_ingress_self" {
  security_group_id            = aws_security_group.public_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id

  ip_protocol = "-1"

  tags = merge(
    { Name = "${var.environment}-public-sg-self-ingress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "public_ingress_ipv4" {
  count             = length(local.service_ports)
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = tonumber(local.service_ports[count.index])
  to_port     = tonumber(local.service_ports[count.index])

  tags = merge(
    { Name = "${var.environment}-ec2-sg-ingress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "public_ingress_ipv6" {
  count             = length(local.service_ports)
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv6         = "::/0"

  ip_protocol = "tcp"
  from_port   = tonumber(local.service_ports[count.index])
  to_port     = tonumber(local.service_ports[count.index])

  tags = merge(
    { Name = "${var.environment}-public-sg-ingress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "public_egress_ipv4" {
  security_group_id = aws_security_group.public_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = merge(
    { Name = "${var.environment}-public-sg-egress-rule" },
    var.tags
  )
}

resource "aws_vpc_security_group_egress_rule" "public_egress_ipv6" {
  security_group_id = aws_security_group.public_sg.id

  cidr_ipv6   = "::/0"
  ip_protocol = "-1"

  tags = merge(
    { Name = "${var.environment}-public-sg-egress-rule" },
    var.tags
  )
}
