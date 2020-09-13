

locals {
  fqdn = "${var.sub_domain}.${var.domain_name}"
  dns_records = toset(var.sub_domain == "www" ? [local.fqdn, var.domain_name] : [local.fqdn])
  s3_origin_id = "s3-${local.fqdn}"
}

##### CERTIFICATE #####

resource "aws_acm_certificate" "cert" {
  provider          = aws.acm
  domain_name       = var.sub_domain == "www" ? var.domain_name : local.fqdn
  validation_method = "DNS"
  subject_alternative_names = var.sub_domain == "www" ? [local.fqdn] : []
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_record" "validation" {
  provider        = aws.acm
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "main" {
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

##### S3 BUCKET FOR CONTENT #####

resource "aws_s3_bucket" "main" {
  provider = aws.main
  bucket   = local.fqdn
  acl      = "private"
  tags     = { 
    Name = "Web site ${local.fqdn}" 
    Environment = var.environment
  } 
  website {
    index_document = "index.html"
    error_document = "index.html" # all routes are served by index.html
  }
  force_destroy = true
}

resource "aws_s3_bucket_object" "main" {
  provider      = aws.main
  bucket        = aws_s3_bucket.main.id
  acl           = "private"

  for_each      = fileset(var.upload_directory, "**/*.*")
  key           = replace(each.value, var.upload_directory, "")
  source        = "${var.upload_directory}/${each.value}"
  etag          = filemd5("${var.upload_directory}/${each.value}")
  content_type  = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1])
}

data "aws_iam_policy_document" "s3_policy" {
  provider = aws.main
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  provider = aws.main
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

####### CLOUD_FRONT

resource "aws_cloudfront_origin_access_identity" "main" {
  provider = aws.main
  comment = "For website ${local.fqdn}"
}

resource "aws_cloudfront_distribution" "main" {
  provider = aws.main

  # depends_on = [aws_acm_certificate_validation.cert]
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "For website ${local.fqdn}"
  default_root_object = "index.html"
  custom_error_response  {
    error_caching_min_ttl = 3000
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  aliases = local.dns_records

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"] ## ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    #   restriction_type = "whitelist"
    #   locations        = ["US", "CA", "GB", "DE"]
    }
  }
  tags = {
    Name = "Web site ${local.fqdn}" 
    Environment = var.environment
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.main.certificate_arn # aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
}

##### ROUTE53 #####

# Create DNS entries for the domain to cloud front
resource "aws_route53_record" "main" {
  provider = aws.main
  for_each = local.dns_records
  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id 
    evaluate_target_health = true
  }
}
