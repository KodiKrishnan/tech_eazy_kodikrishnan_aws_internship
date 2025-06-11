terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# SSH key
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "Tf_keypair" {
  key_name   = "Tf_keypair-${var.environment}"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "Tf_keypair" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "tf_keypair_${var.environment}.pem"
  file_permission = "0400"
}

# Security group
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

# IAM: Assume role policy for EC2
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Roles
resource "aws_iam_role" "s3_readonly" {
  name               = "s3-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

resource "aws_iam_role" "s3_writeonly" {
  name               = "s3-writeonly-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_policy" "writeonly_s3_policy" {
  name = "WriteOnlyS3Policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:CreateBucket", "s3:PutObject"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "write_attach" {
  role       = aws_iam_role.s3_writeonly.name
  policy_arn = aws_iam_policy.writeonly_s3_policy.arn
}

resource "aws_iam_instance_profile" "write_profile" {
  name = "writeonly-profile"
  role = aws_iam_role.s3_writeonly.name
}

# S3 Bucket (with lifecycle)
resource "aws_s3_bucket" "log_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true
  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration {
      days = 7
    }
    filter {
      prefix = "logs/"
    }
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.Tf_keypair.key_name
  vpc_security_group_ids      = [aws_security_group.ssh_http_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.write_profile.name
  
  user_data                   = templatefile("${path.module}/user-data.sh", {
    bucket_name = var.s3_bucket_name
  })
  disable_api_termination     = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name        = "AppServer-${var.environment}"
    Environment = var.environment
  }
}
