resource "aws_cloudfront_cache_policy" "cf" {
  provider = aws.us-east-1
  
  name        = "apdev-cdn-policy"
  comment     = "apdev-cdn-policy"
  default_ttl = 50
  max_ttl     = 100
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "whitelist"
    
      query_strings {
        items = ["first_name","last_name"]
      }
    }

    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
  }
}


resource "aws_cloudfront_distribution" "cf" {
  provider = aws.us-east-1

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  enabled         = true
  is_ipv6_enabled = false
  comment         = "CloudFront For ALB"

  default_cache_behavior {
    target_origin_id       = aws_lb.alb.id
    cache_policy_id        = aws_cloudfront_cache_policy.cf.id
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern             = "/v1/*"
    target_origin_id         = aws_lb.alb.id
    cache_policy_id          = aws_cloudfront_cache_policy.cf.id
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.waf.arn

  tags = {
    Name = "apdev-cdn"
  }
}