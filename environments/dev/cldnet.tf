#Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name        = "ecs-vpc"
    Environment = "dev"
  }
}

# Create Private Subnets
resource "aws_subnet" "ecs_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "ecs-subnet1"
    Environment = "dev"
  }
}

resource "aws_subnet" "ecs_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "ecs-subnet2"
    Environment = "dev"
  }
}



resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_1.id
  }

  tags = {
    Name = "private-route-table-1"
  }
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_2.id
  }

  tags = {
    Name = "private-route-table-1"
  }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.ecs_subnet_1.id  # Private Subnet 1 (AZ-1)
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.ecs_subnet_2.id  # Private Subnet 2 (AZ-2)
  route_table_id = aws_route_table.private_route_table_2.id
}




###########private end 

###################public start


resource "aws_subnet" "ecs_pubsubnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"         # Example CIDR, adjust as needed
  map_public_ip_on_launch = true                  # Enable public IPs
  availability_zone       = "us-east-2a"          # Replace with your AZ
}

resource "aws_subnet" "ecs_pubsubnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"         # Example CIDR, adjust as needed
  map_public_ip_on_launch = true                  # Enable public IPs
  availability_zone       = "us-east-2b"          # Replace with your AZ
}


resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ecs_igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }
}

resource "aws_route_table_association" "public_assoc1" {
  subnet_id      = aws_subnet.ecs_pubsubnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc2" {
  subnet_id      = aws_subnet.ecs_pubsubnet2.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_eip" "nat_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_eip_2" {
  vpc = true
}


resource "aws_nat_gateway" "nat_gw_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.ecs_pubsubnet1.id  # Public Subnet 1 (AZ-1)
  tags = {
    Name = "nat-gateway-1"
  }
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.ecs_pubsubnet2.id  # Public Subnet 2 (AZ-2)
  tags = {
    Name = "nat-gateway-2"
  }
}
