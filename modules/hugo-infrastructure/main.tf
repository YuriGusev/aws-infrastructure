/*
 * Origin for Cloud Front to access s3 bucket
 */
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Origin access identity to access S3 bucket"
}

/*
 * Bucket to host the web page
 */
resource "aws_s3_bucket" "hugo" {
  bucket        = var.bucket_name
  force_destroy = true
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.hugo.arn}/public/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.hugo.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  /* Allow deployment user with write access */
  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.hugo.arn}/public/*"]

    principals {
      type        = "AWS"
      identifiers = [var.deployment_user_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "hugo_bucket_policy" {
  bucket = aws_s3_bucket.hugo.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_cloudfront_distribution" "hugo" {
  count      = 1
  depends_on = [aws_s3_bucket.hugo]

  origin {
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }

    domain_name = aws_s3_bucket.hugo.bucket_regional_domain_name

    origin_id   = var.s3_origin_id
    origin_path = var.origin_path
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = var.aliases

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy

    // Using CloudFront defaults, tune to liking
    min_ttl     = var.cf_min_ttl
    default_ttl = var.cf_default_ttl
    max_ttl     = var.cf_max_ttl
  }

  price_class = var.cf_price_class

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
