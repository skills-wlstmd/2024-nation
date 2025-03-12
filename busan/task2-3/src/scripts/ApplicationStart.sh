#!/bin/bash
ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
docker run -d -p 80:8080 $ACCOUNT.dkr.ecr.ap-northeast-2.amazonaws.com/wsi-ecr:latest