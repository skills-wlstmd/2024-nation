resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3_oac_${random_string.bucket_random.result}"
  description                       = "S3 OAC Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "example" {
  name        = "wsi-cdn-policy"
  comment     = "test"
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
        items = ["width","height"]
      }
    }
    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_distribution" "cf_dist" {
  origin {
    domain_name              = aws_s3_bucket.source.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = aws_s3_bucket.source.id
  }
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "CloudFront For S3, ALB"
  default_root_object = "index.html"
  default_cache_behavior {
    cache_policy_id  = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    target_origin_id = aws_s3_bucket.source.id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.test.arn
    }
}
  ordered_cache_behavior {
    path_pattern     = "/images/*"
    cache_policy_id  = aws_cloudfront_cache_policy.example.id
    target_origin_id = aws_s3_bucket.source.id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "redirect-to-https"
    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.lambda.qualified_arn
      include_body = false
    }
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Name = "wsi-cdn"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  depends_on = [
    aws_lambda_function.lambda
  ]
}

resource "aws_cloudfront_function" "test" {
  name    = "cloudfront-function"
  runtime = "cloudfront-js-2.0"
  comment = "my function"
  publish = true
  code    = file("./src/function.js")
}