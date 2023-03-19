terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# Configure AWS provider:

provider "aws" {
  region  = "eu-west-2"
}
