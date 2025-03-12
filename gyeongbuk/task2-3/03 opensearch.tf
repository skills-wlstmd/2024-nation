variable "domain" {
  default = "wsi-opensearch"
}

data "aws_region" "opensearch" {}

data "aws_caller_identity" "opensearch" {}

data "aws_iam_policy_document" "opensearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.opensearch.name}:${data.aws_caller_identity.opensearch.account_id}:domain/${var.domain}/*"]
  }
}

resource "aws_opensearch_domain" "opensearch" {
  domain_name    = var.domain
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type           = "r5.large.search"
    instance_count          = 2
    dedicated_master_enabled = true
    dedicated_master_type   = "r5.large.search"
    dedicated_master_count  = 3
    zone_awareness_enabled  = true
    zone_awareness_config {
      availability_zone_count = 2 
    }
  }

  ebs_options {
    ebs_enabled  = true
    volume_size  = 10
    volume_type  = "gp3"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = "Password01!"
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.opensearch.json

  tags = {
    Name = "wsi-opensearch"
  }
}
