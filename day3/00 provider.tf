terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }

    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }

    archive = {
      source = "hashicorp/archive"
      version = "2.4.0"
    }
  }
}

provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
  profile = "default"
}

provider "aws" {
  alias   = "default"
  region  = "ap-northeast-2"
  profile = "default"
}

provider "tls" {
}

provider "local" {
}

provider "archive" {
}

data "aws_caller_identity" "caller" {
}