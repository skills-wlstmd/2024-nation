terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"
}