provider "aws" {
  region = var.region
  access_key = ""
  secret_key = ""
}
resource "aws_vpc" "project" {
  cidr_block = var.cidr_block
  tags = {
    Name="my_vpc"
  }
}
resource "aws_subnet" "web_server" {
  vpc_id = aws_vpc.project.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  depends_on = [ aws_vpc.project ]
  tags = {
    Name="web_server"
  }
}
resource "aws_subnet" "db_subnet" {
  vpc_id = aws_vpc.project.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"
  depends_on = [ aws_vpc.project ]
  tags = {
    Name="db_subnet"
  }
}
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.project.id
  tags = {
    Name="my_route_table"
  }
}
resource "aws_route_table_association" "web_server" {
  subnet_id = aws_subnet.web_server.id
  route_table_id = aws_route_table.routetable.id
}
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.project.id
  depends_on = [ aws_vpc.project ]
  tags = {
    Name="my_igw"
  }
}
resource "aws_route" "default" {
  route_table_id = aws_route_table.routetable.id
  destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.my_igw.id
}
resource "aws_security_group" "sg_webserver" {
  vpc_id = aws_vpc.project.id
  ingress  {
protocol = "tcp"
from_port = "80"
to_port = "80"
cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = "22"
    to_port = "22"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = "0"
    to_port = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "db_server" {
  vpc_id = aws_vpc.project.id
  ingress {
    protocol = "tcp"
    from_port = "3306"
    to_port = "3306"
    security_groups = [aws_security_group.sg_webserver.id]
  }
  ingress {
    protocol = "tcp"
    from_port = "22"
    to_port = "22"
    security_groups = [aws_security_group.sg_webserver.id]
  }
  egress {
    protocol = "-1"
    from_port = "0"
    to_port = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "tls_private_key" "web_key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "web_key" {
  key_name = "web_server"
  public_key = tls_private_key.web_key.public_key_openssh
}
resource "local_file" "keypair" {
  content = tls_private_key.web_key.private_key_pem
  filename = "web_server.pem"
}
resource "aws_instance" "web_server" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = "web_server"
  subnet_id = aws_subnet.web_server.id
  security_groups = [aws_security_group.sg_webserver.id]
  tags = {
    Name="webserver"
  }
}
resource "aws_instance" "dbserver" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.db_subnet.id
  security_groups = [aws_security_group.db_server.id]
  key_name = "web_server"
  tags = {
    Name="dbserver"
  }
}
resource "null_resource" "copy_key_ec2" {
  depends_on = [aws_instance.web_server]

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i web_server.pem web_server.pem bitnami@${aws_instance.web_server.public_ip}:/home/bitnami"
  }
}

resource "null_resource" "running_the_website" {
  depends_on = [aws_instance.dbserver, aws_instance.web_server]

  provisioner "local-exec" {
    command = "start chrome ${aws_instance.web_server.public_ip}"
  }
}
resource "aws_eip" "eip" {
  depends_on = [ aws_internet_gateway.my_igw ]
}
resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.web_server.id
  depends_on = [ aws_eip.eip ]
}
resource "aws_route_table" "private_route" {
vpc_id = aws_vpc.project.id
route {
  cidr_block="0.0.0.0/0"
nat_gateway_id=aws_nat_gateway.my_nat.id
}
tags = {
  Name="private_route"
}
}
resource "aws_route_table_association" "private_route" {
route_table_id=aws_route_table.private_route.id
subnet_id = aws_subnet.db_subnet.id
}
