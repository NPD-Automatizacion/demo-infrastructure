terraform {
  required_version = "~>1.6"

  backend "s3" {
    bucket = "generalinfrastructure"
    key    = "democi/terraform.state"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# AWS Security Group
resource "aws_security_group" "sg_ci_demo_instances" {
  name = "Allow ssh from everywhere"

  ingress {
    description = "All connections from my Computer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS Elastic IP
resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.demo_instance.id
  allocation_id = "eipalloc-0fa6b8f05f184e3f1"
  depends_on    = [aws_instance.demo_instance]
}


# AWS Instances
resource "aws_instance" "demo_instance" {
  instance_type               = var.demo_instance_type
  ami                         = var.ami
  associate_public_ip_address = true
  availability_zone           = var.availability_zone
  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = var.volume_size
    volume_type           = var.volume_type
  }
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_ci_demo_instances.id]

  tags = {
    Name        = "Master Instance - ${var.environment}"
    Environment = var.environment
  }
}