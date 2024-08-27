provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

# S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "website" {
  bucket = "my-app-static-website"  # Change to a unique name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website_policy.json
}

data "aws_iam_policy_document" "website_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn.cloudfront_origin_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled      = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    cached_methods  = ["GET", "HEAD"]

    forward_cookie {
      forward = "none"
    }

    forward_query_string = false
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "my-app-cdn"
  }
}

resource "aws_cloudfront_origin_access_identity" "cdn" {
  comment = "Origin Access Identity for my app"
}
