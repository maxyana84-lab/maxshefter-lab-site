variable "aws_region" {
  description = "Region for all resources (must be us-east-1 for the CloudFront certificate)."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Apex domain of the site."
  type        = string
  default     = "maxshefter-lab.online"
}

variable "github_repo" {
  description = "GitHub repo (owner/name) allowed to deploy via OIDC."
  type        = string
  default     = "maxyana84-lab/maxshefter-lab-site"
}

variable "create_github_oidc_provider" {
  description = "Set to false if the GitHub OIDC provider already exists in this AWS account."
  type        = bool
  default     = true
}
