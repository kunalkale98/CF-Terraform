
# create VPC
resource "aws_vpc" "VPC" {
  cidr_block       = "10.200.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  instance_tenancy = "default"

  tags = {
    Name = "VPC"
  }
}
 # create Internet-getway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "internet_gateway"
  }
}
 #create Public subnet 1ter
resource "aws_subnet" "Public-Subnet-1" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.200.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-1"
  }
}

#create Public subnet 2
resource "aws_subnet" "Public-Subnet-2" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.200.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-2"
  }
}


#public route table
resource "aws_route_table" "Public-route" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id 
  }
  tags = {
    Name = "Public-route"
  }
}
  # route table association Public 1
resource "aws_route_table_association" "Public-route-association-1" {
  subnet_id      = aws_subnet.Public-Subnet-1.id
  route_table_id = aws_route_table.Public-route.id
}
 # route table association Public 2
resource "aws_route_table_association" "Public-route-association-2" {
  subnet_id      = aws_subnet.Public-Subnet-2.id
  route_table_id = aws_route_table.Public-route.id
}

#create Private subnet 1
resource "aws_subnet" "Private-Subnet-1" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.200.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet-1"
  }
}

#create private subnet 2
resource "aws_subnet" "Private-Subnet-2" {
  vpc_id     = aws_vpc.VPC.id
  cidr_block = "10.200.3.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private-Subnet-2"
  }
}

resource "aws_eip" "my-eip" {
  vpc = true
}

resource "aws_nat_gateway" "natgateway" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = aws_subnet.Public-Subnet-1.id

  tags = {
    Name = "natgateway"
  }
}

resource "aws_route_table" "Private-route-table" {
  vpc_id = aws_vpc.VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgateway.id 
  }
  tags = {
    Name = "Private-route-table"
  }
}

resource "aws_route_table_association" "Private-route-association-1" {
  subnet_id      = aws_subnet.Private-Subnet-1.id
  route_table_id = aws_route_table.Private-route-table.id
}

resource "aws_route_table_association" "Private-route-association-2" {
  subnet_id      = aws_subnet.Private-Subnet-2.id
  route_table_id = aws_route_table.Private-route-table.id
}

resource "aws_db_instance" "chatapp-db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.20"
  instance_class       = "db.t2.micro"
  name                 = "${var.db_name}"
  username             = "${var.db_user}"
  password             = "${var.db_pass}"
  availability_zone    = "us-east-1a"
  skip_final_snapshot = true
  db_subnet_group_name = "${aws_db_subnet_group.db-subnet-group.id}"
  vpc_security_group_ids= ["${aws_security_group.db-sg.id}"]
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db-subnet-group"
  subnet_ids = ["${aws_subnet.Private-Subnet-1.id}", "${aws_subnet.Private-Subnet-2.id}"]
}

resource "aws_security_group" "db-sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.VPC.id
}

resource "aws_security_group_rule" "db-sg-ingress" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.db-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "db-sg-egress" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.db-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}