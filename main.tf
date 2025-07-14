resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    {
        vpc_tags=var.vpc_tags
    }
  )
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
        Name = var.igw_tags
    },
    {
        Name = var.project_name
    }
  )
}
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_block)
    map_public_ip_on_launch = true
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-public-${local.azs[count.index]}"
    }
  )
}
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-private-${local.azs[count.index]}"
    }
  )
}
resource "aws_subnet" "database_subnet" {
  count = length(var.database_subnet_cidr_block)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidr_block[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-database-${local.azs[count.index]}"
    }
  )
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public_rt"
    },
    var.public_route_table_tags
  )
}
resource "aws_eip" "elastic_ip" {
  domain   = "vpc"
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id # we are giving 0 as we have 2 subnets so it will be provisioned to ap-south-1a if we give 1 it will connect to ap-south-1b

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.nat_gateway_tags
  )
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  # in public route table we were connect through internet gateway but in private route table
  # we are connecting through nat gateway to internet 
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private_rt"
    },
    var.private_route_table_tags
  )
}
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.main.id

  # in public route table we were connect through internet gateway but in private route table
  # we are connecting through nat gateway to internet 
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-database_rt"
    },
    var.database_route_table_tags
  )
}
resource "aws_route_table_association" "public_subnet_association" {
  count = length(var.public_subnet_cidr_block)
  subnet_id = element(aws_subnet.public_subnet[*].id, count.index)

#  fucntion --> element(aws_subnet.public_subnet[*].id, count.index)
#  above function will fetch list of subnets which are "public-subnet-1" and "public-subnet-2"
#  out of which "count.index" will select all list and perform action

  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "private_subnet_association" {
  count = length(var.private_subnet_cidr_block)
  subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "database_subnet_association" {
  count = length(var.database_subnet_cidr_block)
  subnet_id = element(aws_subnet.database_subnet[*].id, count.index)
  route_table_id = aws_route_table.database_rt.id
}

# we are just creating database subnet groups
resource "aws_db_subnet_group" "roboshop-database" {
  name       = var.project_name
  subnet_ids = aws_subnet.database_subnet[*].id

  tags = merge(
    var.common_tags,
    {
        Name = var.project_name
    },
    var.db_subnet_group_tags
  )
}