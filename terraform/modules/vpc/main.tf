# VPC Module for Self-Healing GitOps Platform
# Creates a VPC with public and private subnets, NAT gateways, and internet gateway

variable "name" {
  description = "Name to be used on all resources as prefix"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones for the subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnets CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnets CIDR blocks"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Whether to create a VPN gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Create VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# NAT Gateways (if enabled)
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.azs) : 0

  vpc = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eap-${count.index}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count  = var.enable_nat_gateway ? length(var.azs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-natgw-${count.index}"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index}"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${count.index}"
    }
  )
}

# Route Tables
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# Private Route Tables (one per AZ if NAT is enabled)
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.azs) : 1
  vpc_id = aws_vpc.this.id

  # Default route to NAT gateway (if enabled) or blackhole
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [0] : []
    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = element(aws_nat_gateway.this.*.id, route.offset)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt-${count.index}"
    }
  )
}

# Associate subnets with route tables
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, min(count.index, length(aws_route_table.private) - 1))
}

# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "default_security_group_id" {
  description = "The ID of the default security group in the VPC"
  value       = aws_vpc.this.default_security_group_id
}