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

# This data source gets the Availability Zones in the region, which we'll use for our subnets.
data "aws_availability_zones" "available" {}

