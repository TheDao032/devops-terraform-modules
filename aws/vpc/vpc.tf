locals {
  azs = sort(var.azs)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    { Name = var.environment },
    var.tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    { Name = var.environment },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count             = length(var.public_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    { Name = "${var.environment}-public-${count.index}" },
    # { "kubernetes.io/cluster/${var.environment}" = "shared" },
    # { "kubernetes.io/role/elb" = "1" },
    var.tags
  )
}

resource "aws_route_table" "public" {
  count  = length(var.public_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    { Name = "${var.environment}-public-${count.index}" },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}


resource "aws_subnet" "private" {
  count             = length(var.private_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    { Name = "${var.environment}-private-${count.index}" },
    # { "kubernetes.io/cluster/${var.environment}" = "shared" },
    # { "kubernetes.io/role/internal-elb" = "1" },
    var.tags
  )
}

resource "aws_eip" "nat" {
  count  = length(var.public_cidr)
  domain = "vpc"

  tags = merge(
    { Name = "${var.environment}-NAT-${count.index}" },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.private[count.index].id

  tags = merge(
    { Name = "${var.environment}-${count.index}" },
    var.tags
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count  = length(var.private_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    { Name = "${var.environment}-private-${count.index}" },
    var.tags
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"
#
#   name = var.environment
#   cidr = var.vpc_cidr_block
#
#   azs             = local.azs
#   private_subnets = var.private_cidr
#   public_subnets  = var.public_cidr
#
#   enable_dns_hostnames = true
#
#   # One NAT Gateway per subnet
#   enable_nat_gateway     = true
#   single_nat_gateway     = false
#   one_nat_gateway_per_az = false
#
#   tags = var.tags
# }
