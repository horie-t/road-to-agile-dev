terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    region  = "us-west-2"
    encrypt = false
    bucket = "terraform.t-horie.com"
    key = "todo_manager/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
  tags = merge(var.tags, {
    Project = var.project_name
    Env     = var.env
  })
}
