provider "aws" {
  region = "us-east-1"  # Change this based on your AWS region
}

# ----------------------------
# VPC
# ----------------------------
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

# ----------------------------
# Public Subnets
# ----------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ----------------------------
# Private Subnets
# ----------------------------
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

# ----------------------------
# Internet Gateway
# ----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# ----------------------------
# Route Table & Association (Public)
# ----------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ----------------------------
# Security Groups
# ----------------------------
# Public Instance Security Group (Allows SSH & HTTP)
resource "aws_security_group" "ssh_sg" {
  name        = "ssh-access"
  description = "Allow SSH & HTTP access"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access"
  }
}

# Private Instance Security Group (Allows SSH & PostgreSQL from Public Instance)
resource "aws_security_group" "db_sg" {
  name        = "db-access"
  description = "Allow DB access from Public Instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow all traffic from Public Instance"
    from_port   = 0
    to_port     =  0
    protocol    = "tcp"
    security_groups = [aws_security_group.ssh_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-access"
  }
}

# ----------------------------
# Key Pair
# Use your actual public key path
# ----------------------------
resource "aws_key_pair" "my_key" {
  key_name   = "my-keypair"
  public_key = file("~/.ssh/id_rsa.pub") 
}

# ----------------------------
# Amazon Linux Instances
# ----------------------------
# Public Instance
resource "aws_instance" "public_instance" {
  ami                    = "ami-053a45fff0a704a47" # Replace with the latest Amazon Linux AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "WEB-Server"
  }
  user_data = file("./AutoBash.sh")
}

# Private Instance
resource "aws_instance" "private_instance" {
  ami                    = "ami-053a45fff0a704a47" # Replace with the latest Amazon Linux AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "BDD-Server"
  }
  user_data = file("./AutoBash.sh")
}

# ----------------------------
# Outputs
# ----------------------------
output "Connect_WebServer_instance_ip" {
  description = "The Public IP of the Web Instance"
  value       = "ssh ec2-user@${aws_instance.public_instance.public_ip}"
}

output "WebServer_Privite_instance_ip" {
  description = "The Private IP of the Database Instance"
  value       = aws_instance.public_instance.private_ip
}

output "BDD_Privite_instance_ip" {
  description = "The Private IP of the Database Instance"
  value       = aws_instance.private_instance.private_ip
}