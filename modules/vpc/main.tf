resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = { Name = "${var.name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = element(var.azs, tonumber(each.key))
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : idx => cidr }
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = element(var.azs, tonumber(each.key))
  tags = { Name = "${var.name}-private-${each.key}" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.name}-igw" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
  depends_on = [aws_internet_gateway.gw]
  tags = { Name = "${var.name}-nat" }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route table using NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = aws_route_table.private.id
}
