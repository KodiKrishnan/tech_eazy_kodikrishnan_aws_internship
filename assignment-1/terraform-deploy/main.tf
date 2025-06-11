terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Generate a new SSH key pair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "Tf_keypair" {
  key_name   = "Tf_keypair-${var.environment}"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "Tf_keypair" {
  content        = tls_private_key.rsa.private_key_pem
  filename       = "tf_keypair_${var.environment}.pem"
  file_permission = "0400"
}

# Security group for SSH and HTTP
resource "aws_security_group" "ssh_http_sg" {
  name        = "ssh-http-sg-${var.environment}"
  description = "Allow SSH and HTTP"
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
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
    Name = "ssh-http-${var.environment}"
  }
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.Tf_keypair.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http_sg.id]
  user_data = file("${path.module}/user-data.sh")
  disable_api_termination = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "AppServer-${var.environment}"
    Environment = var.environment
  }
}

#SNS creation
resource "aws_sns_topic" "app_status" {
  name = "ec2-app-status"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.app_status.arn
  protocol  = "email"
  endpoint  = "kodi.m@infosoftjoin.in"
}
