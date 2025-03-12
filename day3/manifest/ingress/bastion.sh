# Employee
export SECRET_NAME=$(aws secretsmanager list-secrets --query "SecretList[?Name=='rds-secret'].Name" --output text)
export MYSQL_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".username")
export MYSQL_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".password")
export MYSQL_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".proxy_host")
export MYSQL_PORT=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".proxy_port")
export MYSQL_DBNAME=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".dbname")

IMAGE_URL=$(aws ecr describe-repositories --repository-name apdev-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name apdev-ecr --query "imageDetails[?contains(imageTags, 'employee')].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
sed -i "s|dbusername|$MYSQL_USER|" deployment.yaml
sed -i "s|dbpassword|$MYSQL_PASSWORD|" deployment.yaml
sed -i "s|dbhost|$MYSQL_HOST|" deployment.yaml
sed -i "s|dbport|$MYSQL_PORT|" deployment.yaml
sed -i "s|dbname|$MYSQL_DBNAME|" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# Token
IMAGE_URL=$(aws ecr describe-repositories --repository-name apdev-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name apdev-ecr --query "imageDetails[?contains(imageTags, 'token')].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# Ingress
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=apdev-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=apdev-public-a" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=apdev-public-b" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=apdev-app-a" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=apdev-app-b" --query "Subnets[].SubnetId[]" --region ap-northeast-2 --output text)

public_subnet_name=("$public_a" "$public_b")
private_subnet_name=("$private_a" "$private_b")

for name in "${public_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/elb,Value=1
done

for name in "${private_subnet_name[@]}"
do
    aws ec2 create-tags --resources $name --tags Key=kubernetes.io/role/internal-elb,Value=1
done

WAF_ARN=$(aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-2 --query "WebACLs[?Name=='apdev-waf'].ARN" --output text)
sed -i "s|waf_arn|$WAF_ARN|g" ingress.yaml
kubectl apply -f ingress.yaml