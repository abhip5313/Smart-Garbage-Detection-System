resource "aws_cloudfront_distribution" "ui_cdn" {

  origin {
    domain_name = aws_s3_bucket.ui_bucket.bucket_regional_domain_name
    origin_id   = "s3-ui-origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    target_origin_id = "s3-ui-origin"

    viewer_protocol_policy = "redirect-to-https" # 🔥 HTTP → HTTPS

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 🔥 free HTTPS
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}