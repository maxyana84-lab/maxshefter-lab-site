output "name_servers" {
  description = "Put these 4 servers into Namecheap → Nameservers → Custom DNS."
  value       = aws_route53_zone.main.name_servers
}

output "bucket_name" {
  description = "GitHub variable S3_BUCKET."
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "GitHub variable CLOUDFRONT_DISTRIBUTION_ID."
  value       = aws_cloudfront_distribution.site.id
}

output "github_deploy_role_arn" {
  description = "GitHub variable AWS_ROLE_ARN."
  value       = aws_iam_role.github_deploy.arn
}

output "site_url" {
  value = "https://${var.domain_name}"
}
