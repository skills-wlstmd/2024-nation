resource "aws_wafv2_web_acl" "waf" {
  provider = aws.us-east-1

  name  = "apdev-waf"
  # scope = "REGIONAL"
  scope = "CLOUDFRONT"

  default_action {
    block {
      custom_response {
        response_code = 403
        custom_response_body_key = "error-text"
      }
    }
  }

  custom_response_body {
    key          = "error-text"
    content      = "Error"
    content_type = "TEXT_PLAIN"
  }

  rule {
    name     = "token-rule"
    priority = 0

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/v1/token"
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
          byte_match_statement {
            search_string = "POST"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "length"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope       = "KEY"
                oversize_handling = "MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    action {
      allow {}
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "token-rule"
    }
  }

  rule {
    name     = "healthcheck"
    priority = 1

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/healthcheck"
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
          byte_match_statement {
            search_string = "GET"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    action {
      allow {}
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "healthcheck"
    }
  }

  rule {
    name     = "employees-post"
    priority = 2

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/v1/employee"
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
          byte_match_statement {
            search_string = "POST"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "emp_no"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "birth_date"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "first_name"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "last_name"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "gender"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "hire_date"
            field_to_match {
              json_body {
                match_pattern {
                  all {}
                }
                match_scope                 = "KEY"
                invalid_fallback_behavior   = "NO_MATCH"
                oversize_handling           = "NO_MATCH"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    action {
      allow {}
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "employees-post"
    }
  }

  rule {
    name     = "employee-get"
    priority = 3

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string = "/v1/employee"
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
          byte_match_statement {
            search_string = "GET"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }

        statement {
          byte_match_statement {
            search_string = "first_name="
            field_to_match {
              query_string {}
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
            search_string = "last_name="
            field_to_match {
              query_string {}
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

    action {
      allow {}
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "employee-get"
    }
  }

  rule {
    name     = "path-policy"
    priority = 4

    statement {
      and_statement {
        statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string = "/v1/token"
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
          }
        }

        statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string = "/healthcheck"
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
          }
        }

        statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string = "/v1/employee"
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
          }
        }
      }
    }

    action {
      block {
        custom_response {
          response_code = 404
        }
      }
    }

    visibility_config {
      sampled_requests_enabled  = true
      cloudwatch_metrics_enabled = true
      metric_name                = "path-policy"
    }
  }


  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "apdev-waf"
  }
}


# resource "aws_wafv2_web_acl_association" "waf" {
#   resource_arn = aws_lb.alb.arn
#   web_acl_arn  = aws_wafv2_web_acl.waf.arn
# }