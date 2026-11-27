terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: remote state. Create the bucket once, then uncomment and run `terraform init -migrate-state`.
  # backend "s3" {
  #   bucket       = "maxshefter-lab-tfstate"
  #   key          = "site/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}

# CloudFront requires its ACM certificate in us-east-1, so everything lives there.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "maxshefter-lab-site"
      ManagedBy = "terraform"
    }
  }
}
