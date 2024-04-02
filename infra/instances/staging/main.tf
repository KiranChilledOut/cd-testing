terraform {
  backend "remote" {
    organization = "kautomate"

    workspaces {
      name = "clidriven"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }

  required_version = ">= 0.15.0"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

variable "staging_public_key" {
  description = "Staging environment public key value"
  type        = string
}

variable "base_ami_id" {
  description = "Base AMI ID"
  type        = string
}

resource "random_id" "server" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = "${var.base_ami_id}"
  }

  byte_length = 8
}

resource "aws_key_pair" "staging_key" {
  key_name   = "staging-key"
  public_key = var.staging_public_key

  tags = {
    "Name" = "staging_public_key"
  }
}


# This is the main staging environment. We will deploy to this the changes
# to the main branch before deploying to the production environment.
resource "aws_security_group" "this" {
  description = "ssh and https"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
  }]
  name                   = "ssh-https"
  name_prefix            = null
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-01c0cd4d7700ba67f"
}

resource "aws_instance" "staging_cicd_demo" {
  # Read the AMI id "through" the random_id resource to ensure that
  # both will change together.
  ami                         = random_id.server.keepers.ami_id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.staging_key.key_name

  tags = {
    "Name" = "staging_cicd_demo-${random_id.server.hex}"
  }
  depends_on = [aws_security_group.this]
}

output "staging_dns" {
  value = aws_instance.staging_cicd_demo.public_dns
}
