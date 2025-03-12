#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-b" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-app-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-app-b" --query "Subnets[].SubnetId[]" --output text)

sed -i "s|public_a|$public_a|g" cluster.yaml
sed -i "s|public_b|$public_b|g" cluster.yaml
sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml

eksctl create cluster -f cluster.yaml

aws eks --region ap-northeast-2 update-kubeconfig --name wsi-eks-cluster

kubectl apply -f fargate-ns.yaml

# Secret
cd secret
REGION_CORD="ap-northeast-2"
CLUSTER_NAME="wsi-eks-cluster"

cat >secret-policy.json <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"secretsmanager:GetResourcePolicy",
				"secretsmanager:GetSecretValue",
				"secretsmanager:DescribeSecret",
				"secretsmanager:ListSecretVersionIds"
			],
			"Resource": ["*"]
		},
      {
        "Effect": "Allow",
        "Action": ["kms:Decrypt"],
        "Resource": ["*"]
      }
    ]
}
EOF

POLICY_ARN=$(aws --region "$REGION_CORD" --query Policy.Arn --output text iam create-policy --policy-name secretsmanager-policy --policy-document file://secret-policy.json)

eksctl create iamserviceaccount \
    --name external-secrets-cert-controller \
    --region="$REGION_CORD" \
    --cluster "$CLUSTER_NAME" \
    --namespace=wsi \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve

helm repo add external-secrets https://charts.external-secrets.io

kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=wsi \
  -n wsi \
  --overwrite

kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n wsi\
  --overwrite

cat > values.yaml <<EOF
{
  "installCRDs": true,
  "nodeSelector": {
    "type": "addon"
  },
  "webhook": {
    "nodeSelector": {
      "type": "addon"
    }
  },
  "certController": {
    "nodeSelector": {
      "type": "addon"
    }
  }
}
EOF

helm install external-secrets \
   external-secrets/external-secrets \
   -n wsi\
   -f values.yaml \
   --set serviceAccount.create=false

kubectl apply -f secretstore.yaml

kubectl apply -f customer.yaml
kubectl apply -f product.yaml
kubectl apply -f order.yaml

# Logging
cd logging
kubectl apply -f ns.yaml

eksctl create iamserviceaccount \
    --name fluentd \
    --region=ap-northeast-2 \
    --cluster wsi-eks-cluster \
    --namespace=fluentd \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess \
    --override-existing-serviceaccounts \
    --approve 

kubectl create configmap cluster-info \
    --from-literal=cluster.name=wsi-eks-cluster \
    --from-literal=logs.region=ap-northeast-2 -n fluentd

curl -o permissions.json https://raw.githubusercontent.com/aws-samples/amazon-eks-fluent-logging-examples/mainline/examples/fargate/cloudwatchlogs/permissions.json

EKS_CLUISTER_NAME="wsi-eks-cluster"
REGION_CODE=$(aws configure get default.region --output text)
FARGATE_POLICY_ARN=$(aws --region "$REGION_CODE" --query Policy.Arn --output text iam create-policy --policy-name fargate-policy --policy-document file://permissions.json)
FARGATE_ROLE_NAME=$(aws iam list-roles --query "Roles[?contains(RoleName, 'eksctl-wsi-eks-cluster-clus-FargatePodExecutionRole')].RoleName" --output text)
NODE_GROUP=$(aws iam get-role --role-name $FARGATE_ROLE_NAME --query "Role.RoleName" --output text)

aws iam attach-role-policy --policy-arn $FARGATE_POLICY_ARN --role-name $NODE_GROUP

kubectl apply -f fluentd.yaml
kubectl apply -f service.yaml
SVC_CLUSTER_IP=$(kubectl get svc -n fluentd -o json | jq -r '.items[].spec.clusterIP')

sed -i "s|SVC_IP|$SVC_CLUSTER_IP|g" customer.yaml
kubectl apply -f customer.yaml

sed -i "s|SVC_IP|$SVC_CLUSTER_IP|g" product.yaml
kubectl apply -f product.yaml

sed -i "s|SVC_IP|$SVC_CLUSTER_IP|g" order.yaml
kubectl apply -f order.yaml

# Customer
cd customer
IMAGE_URL=$(aws ecr describe-repositories --repository-name customer-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name customer-ecr --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Product
cd product
IMAGE_URL=$(aws ecr describe-repositories --repository-name product-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name product-ecr --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Order
cd order
eksctl create iamserviceaccount \
    --name dynamodb-pull-sa \
    --region=ap-northeast-2 \
    --cluster wsi-eks-cluster \
    --namespace=wsi\
    --attach-policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" \
    --override-existing-serviceaccounts \
    --approve

#!/bin/bash
ROLE_ARN=$(eksctl get iamserviceaccount --cluster wsi-eks-cluster --name dynamodb-pull-sa --namespace wsi --region ap-northeast-2 --output json | jq -r '.[].status.roleARN')
ROLE_NAME=$(aws iam get-role --role-name $(aws iam list-roles --query "Roles[?Arn=='$ROLE_ARN'].RoleName" --output text) --query "Role.RoleName" --output text)
keys=$(aws kms list-keys --output json)
key_ids=$(echo $keys | jq -r '.Keys[].KeyId')
for key_id in $key_ids; do
    name_tag=$(aws kms list-resource-tags --key-id $key_id --query "Tags[].TagValue" --output text 2> /dev/null)
    if [ "$name_tag" == "db-kms" ]; then
        kms_arn=$(aws kms describe-key --key-id $key_id --query "KeyMetadata.Arn" --output text)
    fi
done

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name AllowKMSDecrypt \
    --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Action\": \"kms:Decrypt\",
                \"Resource\": \"${kms_arn}\"
            }
        ]
    }"

IMAGE_URL=$(aws ecr describe-repositories --repository-name order-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name order-ecr --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Ingress
cat <<EOF> values.yaml
nodeSelector: {
  type: addon
}
EOF

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wsi-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -f values.yaml

sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='wsi-app-alb-sg'].GroupId" --output text)
waf_arn=$(aws wafv2 list-web-acls --scope REGIONAL --region ap-northeast-2 --query "WebACLs[].ARN" --output text)

sed -i "s|sg_id|$sg_id|g" ingress.yaml
sed -i "s|waf_arn|$waf_arn|g" ingress.yaml

cluster_sg_id=$(aws eks describe-cluster --name wsi-eks-cluster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id $cluster_sg_id --protocol tcp --port 8080 --source-group $sg_id > /dev/null

#!/bin/bash
public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-a" --query "Subnets[].SubnetId[]" --output text)
public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-b" --query "Subnets[].SubnetId[]" --output text)
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-app-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-app-b" --query "Subnets[].SubnetId[]" --output text)

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

kubectl apply -f ingress.yaml

# Network Policy
cd networkpolicy
kubectl apply -f customer.yaml
kubectl apply -f product.yaml