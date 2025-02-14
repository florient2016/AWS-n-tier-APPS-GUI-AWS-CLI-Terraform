# 🚀 Deploying Amazon Linux on AWS

This guide walks through deploying an **Amazon Linux** instance on AWS using **three different methods**:
- **AWS Management Console (GUI)**
- **AWS CLI**
- **Terraform (Infrastructure as Code)**

## 🏗️ What We Will Set Up
We will create a **secure network architecture** with the following:
- **VPC** (Virtual Private Cloud)
- **Public Subnet** (for the web/application instance)
- **Private Subnet** (for the database instance)
- **Internet Gateway** (for public instance access)
- **Route Table** (to route traffic)
- **Security Groups** (to control inbound/outbound traffic)
- **Key Pair** (for SSH access)
- **Amazon Linux Instances**:
  - One instance in the **public subnet** (for web/application)
  - One instance in the **private subnet** (for the database)

Finally, we will **test SSH connectivity** to the public instance and configure access to the private instance.

---

## 📌 Prerequisites
Before you begin, ensure you have:
- **An AWS account** ([Sign up here](https://aws.amazon.com/))
- **AWS CLI installed & configured** ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))
- **Terraform installed** ([Download Here](https://www.terraform.io/downloads))
- **A terminal (Linux/macOS) or PowerShell (Windows)**

---

# 🔹 1. Deploying Using AWS Management Console (GUI)

## 🛠️ Step 1: Create a VPC
1. Go to **AWS Console** → **VPC Dashboard** → Click **Create VPC**.
2. Choose **VPC only**, name it **my-vpc**.
3. Set **IPv4 CIDR block**: `10.0.0.0/16`.
4. Click **Create**.

## 🛠️ Step 2: Create Public & Private Subnets
1. Go to **Subnets** → **Create subnet**.
2. Select **VPC: my-vpc**.
3. Create:
   - **Public Subnet** (`10.0.1.0/24` in `us-east-1a`)
   - **Private Subnet** (`10.0.2.0/24` in `us-east-1b`)
4. Click **Create**.

## 🛠️ Step 3: Create Internet Gateway & Route Table
1. **Internet Gateway**
   - Go to **Internet Gateways** → Click **Create IGW** (`my-igw`).
   - Attach it to **my-vpc**.

2. **Route Table for Public Subnet**
   - Go to **Route Tables** → Click **Create**.
   - Set name **public-route-table**, attach to **my-vpc**.
   - Add a **route**:  
     - **Destination**: `0.0.0.0/0`
     - **Target**: **Internet Gateway (my-igw)**
   - **Associate** this route table with the **public subnet**.

## 🛠️ Step 4: Create Security Groups
1. Go to **Security Groups** → **Create security group**.
2. Create:
   - **Public Instance Security Group (`ssh-access`)**  
     - Allow **SSH (port 22)** from **your IP**
     - Allow **HTTP (port 80)** from `0.0.0.0/0`
   - **Private Instance Security Group (`db-access`)**  
     - Allow **MySQL/PostgreSQL (port 3306/5432)** only from the **Public Instance Security Group**.

## 🛠️ Step 5: Create Key Pair
1. Go to **EC2** → **Key Pairs** → **Create Key Pair** (`my-keypair`).
2. Download and **store it safely**.

## 🛠️ Step 6: Launch Instances
1. **Public Instance (Web Server)**
   - Use **Amazon Linux 2 AMI**.
   - Instance type: `t2.micro`.
   - **Network**: VPC `my-vpc`, **Subnet**: `public-subnet`.
   - **Enable** public IP.
   - Select **`ssh-access` security group**.
   - Use **`my-keypair`**.
   - Click **Launch**.

2. **Private Instance (Database Server)**
   - Use **Amazon Linux 2 AMI**.
   - Instance type: `t2.micro`.
   - **Network**: VPC `my-vpc`, **Subnet**: `private-subnet`.
   - **Disable** public IP.
   - Select **`db-access` security group**.
   - Use **`my-keypair`**.
   - Click **Launch**.

## 🛠️ Step 7: Test SSH Connectivity
1. Get the **Public IP** of the public instance.
2. Connect via SSH:
   ```bash
   chmod 400 my-keypair.pem
   ssh -i my-keypair.pem ec2-user@<public-instance-ip>
   ```


# 2. Deploying Using AWS CLI
This section provides a step-by-step guide to deploying an Amazon Linux instance using AWS CLI, including: ✅ VPC creation
✅ - **Public & Private Subnets**
✅ - **Routing & Internet Gateway**
✅ - **Security Groups with proper rules**
✅ - **Key Pair generation**
✅ - **Launching a public instance (for web/app) and a private instance (for database)**
✅ - **Testing SSH & PostgreSQL connectivity**

## 🛠️ Step 1: Create a VPC
A VPC (Virtual Private Cloud) is required to isolate network resources.
```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]'
```
Retrieve VPC ID:
```bash
aws ec2 describe-vpcs --query 'Vpcs[?CidrBlock==`10.0.0.0/16`].VpcId' --output text
```
## 🛠️ Step 2: Create Public & Private Subnets
We create:

Public Subnet: 10.0.1.0/24 (for the web/app instance)
Private Subnet: 10.0.2.0/24 (for the database instance)
Create Public Subnet:
```bash
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet}]'
```
Create Private Subnet:
```bash
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-subnet}]'
```
Retrieve Subnet IDs:
```bash
aws ec2 describe-subnets --query 'Subnets[].[SubnetId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
```
## 🛠️ Step 3: Create Internet Gateway & Route Tables
Create Internet Gateway:
```bash
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw}]'
```
Attach IGW to VPC:
```bash
aws ec2 attach-internet-gateway --vpc-id <vpc-id> --internet-gateway-id <igw-id>
```
Create Public Route Table:
```bash
aws ec2 create-route-table --vpc-id <vpc-id> --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-route-table}]'
```
Add a Route to Internet:

```bash
aws ec2 create-route --route-table-id <rtb-id> --destination-cidr-block 0.0.0.0/0 --gateway-id <igw-id>
```
Associate Route Table with Public Subnet:
```bash
aws ec2 associate-route-table --subnet-id <public-subnet-id> --route-table-id <rtb-id>
```

## 🛠️ Step 4: Create Security Groups
We need two security groups:

Public Instance Security Group (ssh-access) - Allows SSH and web traffic.
Private Instance Security Group (db-access) - Allows access from the public instance.
Create Public Instance Security Group:
```bash
aws ec2 create-security-group --group-name ssh-access --description "Allow SSH and HTTP access" --vpc-id <vpc-id>
```
Allow SSH (Port 22) and HTTP (Port 80):

```bash
aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id <sg-id> --protocol tcp --port 80 --cidr 0.0.0.0/0
```
Create Private Instance Security Group:
```bash
aws ec2 create-security-group --group-name db-access --description "Allow access from public instance" --vpc-id <vpc-id>
```
Allow SSH (Port 22) & PostgreSQL (Port 5432) from Public Instance Security Group:

```bash
aws ec2 authorize-security-group-ingress --group-id <db-sg-id> --protocol tcp --port 22 --source-group <sg-id>
aws ec2 authorize-security-group-ingress --group-id <db-sg-id> --protocol tcp --port 5432 --source-group <sg-id>
```

## 🛠️ Step 5: Create Key Pair
```bash
aws ec2 create-key-pair --key-name my-keypair --query 'KeyMaterial' --output text > my-keypair.pem
chmod 400 my-keypair.pem
```
## 🛠️ Step 6: Launch Amazon Linux Instances
Launch a Public Instance:
```bash
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t2.micro \
    --key-name my-keypair \
    --security-group-ids <sg-id> \
    --subnet-id <public-subnet-id> \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=public-instance}]' \
    --associate-public-ip-address
```
Launch a Private Instance:
```bash
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --count 1 \
    --instance-type t2.micro \
    --key-name my-keypair \
    --security-group-ids <db-sg-id> \
    --subnet-id <private-subnet-id> \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=private-instance}]'
```
Retrieve the Public IP:

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=public-instance" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
```
## 🛠️ Step 7: Test SSH & PostgreSQL Connectivity
Connect to the Public Instance:
```bash
ssh -i my-keypair.pem ec2-user@<public-instance-ip>
```
Connect from Public Instance → Private Instance:
```bash
ssh -i my-keypair.pem ec2-user@<private-instance-ip>
```
# 🔹 3. Deploying Using Terraform
📌 What Will Be Deployed?
With Terraform, we will define and deploy the same AWS infrastructure:
## 📂 Step 1: Create a Terraform Configuration File (main.tf)
Create a new Terraform project folder and inside it, create a file named main.tf.
```bash
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
# Subnets
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
    description = "Allow SSH from Public Instance"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.ssh_sg.id]
  }

  ingress {
    description = "Allow PostgreSQL from Public Instance"
    from_port   = 5432
    to_port     = 5432
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
# ----------------------------
resource "aws_key_pair" "my_key" {
  key_name   = "my-keypair"
  public_key = file("~/.ssh/id_rsa.pub") # Use your actual public key path
}

# ----------------------------
# Amazon Linux Instances
# ----------------------------
# Public Instance
resource "aws_instance" "public_instance" {
  ami                    = "ami-0abcdef1234567890" # Replace with the latest Amazon Linux AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "public-instance"
  }
}

# Private Instance
resource "aws_instance" "private_instance" {
  ami                    = "ami-0abcdef1234567890" # Replace with the latest Amazon Linux AMI
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "private-instance"
  }
}

# ----------------------------
# Outputs
# ----------------------------
output "public_instance_ip" {
  description = "The Public IP of the Web Instance"
  value       = aws_instance.public_instance.public_ip
}

output "private_instance_ip" {
  description = "The Private IP of the Database Instance"
  value       = aws_instance.private_instance.private_ip
}
```
## 🛠️ Step 2: Deploy Terraform Code
1️⃣ Initialize, Plan and apply Terraform
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
🎉 Now your cloud infrastructure is fully automated and production-ready! 🚀
# 🎯 Conclusion
This guide showed how to deploy an Amazon Linux instance on AWS using GUI, CLI, and Terraform, with a private DB instance setup. 🚀
