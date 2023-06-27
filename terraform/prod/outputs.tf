output "craft_access_key_id" {
  value = aws_iam_access_key.craft_access_key.id
}

output "craft_access_key_secret" {
  value     = aws_iam_access_key.craft_access_key.secret
  sensitive = true
}

output "craft_bucket_name" {
  value = module.s3_bucket.s3_bucket_id
}

output "cloudfront_distribution_domain" {
  value = module.cdn.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_id" {
  value = module.cdn.cloudfront_distribution_id
}
