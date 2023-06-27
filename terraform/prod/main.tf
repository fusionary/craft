#######################
# Client AWS Account
#######################

#~~~~~~~~#
# Common #
#~~~~~~~~#

data "aws_caller_identity" "aws_caller_identity_client" {}

locals {
  account_id = data.aws_caller_identity.aws_caller_identity_client.account_id

  cloudfront_cache_optimized_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # This is a managed policy provided by AWS
  cloudfront_response_headers_policy_id = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # This is a managed policy provided by AWS

  # @todo: Set locals for resource names.
  s3_bucket_name                  = null
  cloudfront_distribution_comment = null
  craft_user_name                 = null
}

#~~~~#
# S3 #
#~~~~#

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.0"

  bucket = local.s3_bucket_name
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = false

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    enabled = false
  }
}

data "aws_iam_policy_document" "s3_bucket_policy_document" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    principals {
      type = "AWS"
      identifiers = [
        module.cdn.cloudfront_origin_access_identity_iam_arns[0]
      ]
    }

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]

    principals {
      type = "AWS"
      identifiers = [
        module.cdn.cloudfront_origin_access_identity_iam_arns[0]
      ]
    }

    resources = [
      module.s3_bucket.s3_bucket_arn
    ]
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_bucket_policy_document.json
}

#~~~~~~~~~~~~#
# CloudFront #
#~~~~~~~~~~~~#

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  comment             = local.cloudfront_distribution_comment
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_identity = module.s3_bucket.s3_bucket_bucket_domain_name
  }

  origin = {
    s3_origin = {
      domain_name = module.s3_bucket.s3_bucket_bucket_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_identity"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id           = "s3_origin"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = local.cloudfront_cache_optimized_policy_id
    response_headers_policy_id = local.cloudfront_response_headers_policy_id
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    use_forwarded_values       = false
  }

  viewer_certificate = {
    cloudfront_default_certificate = true
  }
}

#~~~~~#
# SES #
#~~~~~#

resource "aws_ses_domain_identity" "ses_domain_identity" {
  count  = var.ses_domain == "" ? 0 : 1
  domain = var.ses_domain
}

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  count  = var.ses_domain == "" ? 0 : 1
  domain = aws_ses_domain_identity.ses_domain_identity[0].domain
}

resource "aws_ses_domain_mail_from" "ses_maiL_from_domain" {
  count            = var.ses_domain == "" ? 0 : 1
  domain           = aws_ses_domain_identity.ses_domain_identity[0].domain
  mail_from_domain = "mail.${aws_ses_domain_identity.ses_domain_identity[0].domain}"
}

#~~~~~#
# IAM #
#~~~~~#

data "aws_iam_policy_document" "craft_user_policy_document" {
  statement {
    sid = "S3Access"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:DeleteObject",
      "s3:GetObjectAcl",
      "s3:PutObjectAcl",
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid = "S3Listing"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      module.s3_bucket.s3_bucket_arn
    ]
  }

  statement {
    sid = "CloudFront"

    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [
      module.cdn.cloudfront_distribution_arn
    ]
  }

  statement {
    sid = "SES"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_user" "craft_user" {
  name = local.craft_user_name
}

resource "aws_iam_access_key" "craft_access_key" {
  user = aws_iam_user.craft_user.id
}

resource "aws_iam_user_policy" "aws_iam_user_policy_craft" {
  name   = "${local.craft_user_name}-policy"
  user   = aws_iam_user.craft_user.id
  policy = data.aws_iam_policy_document.craft_user_policy_document.json
}
