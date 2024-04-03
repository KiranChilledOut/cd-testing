terraform {
  backend "remote" {
    organization = "glich-stream"

    workspaces {
      name = "ci-cd-production"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48"
    }
  }

  required_version = ">= 0.15.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

variable "production_public_key" {
  description = "Production environment public key value"
  type        = string
}

variable "security_group_id" {
  default = "sg-08a9715968510738a"
  type = string
}

data "aws_security_group" "selected" {
  id = var.security_group_id
}

variable "base_ami_id" {
  description = "Base AMI ID"
  type        = string
}

data "aws_key_pair" "production_key" {
  key_name   = "production-key"
  include_public_key  = true

  filter {
    name   = "tag:env"
    values = ["production"]
  }
}

resource "aws_instance" "production_cicd_demo" {
  ami                    = var.base_ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.selected.id]
  key_name               = aws_key_pair.production_key.key_name

  tags = {
    "Name" = "production_cicd_demo"
  }
}

output "production_dns" {
  value = aws_instance.production_cicd_demo.public_dns
}
