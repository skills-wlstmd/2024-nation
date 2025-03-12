resource "aws_wafv2_web_acl" "wsi_waf" {
  name        = "wsi-waf"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  custom_response_body {
    key          = "Blocked"
    content      = "Blocked by WAF"
    content_type = "TEXT_PLAIN"
  }

  rule {
    name     = "token-block"
    priority = 0

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/v1/token/verify"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          or_statement {
            statement {
              byte_match_statement {
                search_string = "eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0"
                field_to_match {
                  single_header {
                    name = "authorization"
                  }
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
                positional_constraint = "CONTAINS"
              }
            }

            statement {
              byte_match_statement {
                search_string = "eyJhbGciOiAibm9uZSIsICJ0eXAiOiAiSldUIn0"
                field_to_match {
                  single_header {
                    name = "authorization"
                  }
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
                positional_constraint = "CONTAINS"
              }
            }
          }
        }
      }
    }

    action {
      block {
        custom_response {
          response_code = 401
          custom_response_body_key = "Blocked"
        }
      }
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "wsi-waf-cw"
    }
  }

  visibility_config {
    sampled_requests_enabled    = true
    cloudwatch_metrics_enabled  = true
    metric_name                 = "wsi-waf"
  }
}

resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = aws_lb.lb.arn
  web_acl_arn  = aws_wafv2_web_acl.wsi_waf.arn
}