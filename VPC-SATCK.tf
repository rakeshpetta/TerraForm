#variable "region" {
#  description = "AWS region"
#  default     = "us-west-2"
#}

provider "aws" {
  region = "us-west-2"
}

#resource "aws_availability_zones" "az" {
#  state = "available"
#
#  providers = {
#    aws = "aws"
#  }
#}

data "aws_availability_zones" "az" {
  state = "available"
}

output "availability_zones" {
  value = data.aws_availability_zones.az.names
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

resource "aws_subnet" "public" {
#  count             = length(aws_availability_zones.az.names)
   count            = length(data.aws_availability_zones.az.names)
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }

  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.az.names)
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index + 100}.0/24"
  availability_zone = element(data.aws_availability_zones.az.names, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }

  map_public_ip_on_launch = false
}


resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "Public Route Table"
  }
}


resource "aws_eip" "nat" {
#  count = length(aws_subnet.public)
  count = 1
}

resource "aws_nat_gateway" "nat" {
#  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[0].id
#  allocation_id  = aws_eip.nat[count.index].id
  allocation_id = aws_eip.nat[0].id

  tags = {
     Name = "Nat Gateway"
#    Name = "NAT Gateway ${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
# count = length(aws_subnet.private)
  vpc_id = aws_vpc.example.id
  route {
    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.nat[count.index].id
    nat_gateway_id = aws_nat_gateway.nat.id
  }  

  tags = {
    Name = "Private Route Table "
  }
}


#resource "aws_route_table" "nat" {
##  count = length(aws_subnet.private)
#  vpc_id = aws_vpc.example.id
#
#  route {
#    cidr_block     = "0.0.0.0/0"
##    nat_gateway_id = aws_nat_gateway.nat[count.index].id
#    nat_gateway_id = aws_nat_gateway.nat.id
#  }
#
#  tags = {
#     Name = "Private Route Table with NAT"
##    Name = "Private Route Table with NAT ${count.index + 1}"
#  }
#}

resource "aws_route_table_association" "nat" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
# subnet_id      = aws_subnet.private[0].id
# route_table_id = aws_route_table.nat[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_instance" "private_instance" {
  count         = 1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private[count.index].id
  ami           = "ami-00aa0673b34e3c150"
}
