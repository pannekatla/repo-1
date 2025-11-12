terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get available subnets in your VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id             = data.aws_subnets.public.ids[0]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = var.instance_name
    Environment = "Development"
    ManagedBy   = "Terraform"
  }

  # Wait for instance to be ready
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    instance_ip = aws_instance.app_server.public_ip
  })
  filename = "${path.module}/inventory.ini"

  depends_on = [aws_instance.app_server]
}

# Output the instance details
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}
