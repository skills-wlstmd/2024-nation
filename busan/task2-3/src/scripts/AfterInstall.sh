#!/bin/bash
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
docker pull $ACCOUNT.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-ecr:latest