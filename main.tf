provider "aws" {
  region = "ap-southeast-1"
}

# Create default VPC if one does not exist
# tfsec:ignore:aws-ec2-no-default-vpc
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default-vpc"
  }
}

# Data source to get all availability zones in the region
data "aws_availability_zones" "available_zones" {}

# Create default subnet in the first availability zone if one does not exist
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default-subnet"
  }
}

# Create security group for the EC2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow HTTP and restricted SSH access"
  vpc_id      = aws_default_vpc.default_vpc.id

  # Allow HTTP access to the web server from anywhere
  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access from a specific IP
  ingress {
    description = "SSH access from specified IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["1.9.9.1/32"]
  }

  # Allow all outbound traffic
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# Use data source to get a registered Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Launch the EC2 instance and configure it using user data
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "letmein"
  user_data              = file("setup_apps.sh")

  # Enabling IMDSv2
  # tfsec:ignore:aws-ec2-enforce-http-token-imds
  metadata_options {
    http_tokens = "required"
  }

  # Setting encryption for the root block device
  # tfsec:ignore:aws-ec2-enable-at-rest-encryption
  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "Reveal.JS Apps"
  }
}

# Outputs for EC2 instance details
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_instance.id
}

output "public_ipv4_address" {
  description = "EC2 Public IP"
  value       = aws_instance.ec2_instance.public_ip
}
#
