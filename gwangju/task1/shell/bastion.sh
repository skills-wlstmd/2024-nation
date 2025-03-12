# Cluster
#!/bin/bash
private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-app-a" --query "Subnets[].SubnetId[]" --output text)
private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=skills-app-b" --query "Subnets[].SubnetId[]" --output text)
sg_id=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='skills-EKS-ControlPlan-SG'].GroupId" --output text)
keys=$(aws kms list-keys --output json)
key_ids=$(echo $keys | jq -r '.Keys[].KeyId')
for key_id in $key_ids; do
    name_tag=$(aws kms list-resource-tags --key-id $key_id --query "Tags[].TagValue" --output text 2> /dev/null)
    if [ "$name_tag" == "eks-kms" ]; then
        kms_arn=$(aws kms describe-key --key-id $key_id --query "KeyMetadata.Arn" --output text)
    fi
done


sed -i "s|private_a|$private_a|g" cluster.yaml
sed -i "s|private_b|$private_b|g" cluster.yaml
sed -i "s|sg_id|$sg_id|g" cluster.yaml
sed -i "s|kms_arn|$kms_arn|g" cluster.yaml

eksctl create cluster -f cluster.yaml

aws eks --region ap-northeast-2 update-kubeconfig --name skills-eks-cluster

kubectl create ns app

kubectl patch deployment coredns -n kube-system --type=json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations", "value": "eks.amazonaws.com/compute-type"}]'
kubectl rollout restart -n kube-system deployment coredns


# Secret
REGION_CORD="ap-northeast-2"
CLUSTER_NAME="skills-eks-cluster"

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
    --namespace=app \
    --attach-policy-arn "$POLICY_ARN" \
    --override-existing-serviceaccounts \
    --approve

helm repo add external-secrets https://charts.external-secrets.io

kubectl annotate serviceaccount external-secrets-cert-controller \
  meta.helm.sh/release-name=external-secrets \
  meta.helm.sh/release-namespace=app \
  -n app \
  --overwrite

kubectl label serviceaccount external-secrets-cert-controller \
  app.kubernetes.io/managed-by=Helm \
  -n app \
  --overwrite

cat > values.yaml <<EOF
{
  "installCRDs": true,
  "nodeSelector": {
    "skills": "app"
  },
  "webhook": {
    "nodeSelector": {
      "skills": "app"
    }
  },
  "certController": {
    "nodeSelector": {
      "skills": "app"
    }
  }
}
EOF

helm install external-secrets \
   external-secrets/external-secrets \
   -n app \
   -f values.yaml \
   --set serviceAccount.create=false

kubectl apply -f secretstore.yaml

kubectl apply -f externalsecret.yaml


# Customer
IMAGE_URL=$(aws ecr describe-repositories --repository-name customer --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name customer --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# Product
IMAGE_URL=$(aws ecr describe-repositories --repository-name product --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name product --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
	kubectl apply -f service.yaml


# Order
eksctl create iamserviceaccount \
    --name dynamodb-pull-sa \
    --region=ap-northeast-2 \
    --cluster skills-eks-cluster \
    --namespace=app \
    --attach-policy-arn "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess" \
    --override-existing-serviceaccounts \
    --approve

# ===================== KMS Policy 수정 ===================== 

#!/bin/bash
ROLE_ARN=$(eksctl get iamserviceaccount --cluster skills-eks-cluster --name dynamodb-pull-sa --namespace app --region ap-northeast-2 --output json | jq -r '.[].status.roleARN')
ROLE_NAME=$(aws iam get-role --role-name $(aws iam list-roles --query "Roles[?Arn=='$ROLE_ARN'].RoleName" --output text) --query "Role.RoleName" --output text)
keys=$(aws kms list-keys --output json)
key_ids=$(echo $keys | jq -r '.Keys[].KeyId')
for key_id in $key_ids; do
    name_tag=$(aws kms list-resource-tags --key-id $key_id --query "Tags[].TagValue" --output text 2> /dev/null)
    if [ "$name_tag" == "gwj-eks-kms" ]; then
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

IMAGE_URL=$(aws ecr describe-repositories --repository-name order --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name order --query "imageDetails[].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# Nginx Ingress Controller
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml # 수정해야함

kubectl apply -f deploy.yaml
kubectl describe deploy ingress-nginx-controller -n ingress-nginx | grep ingress-class

SVC_ID=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o json | jq -r .spec.clusterIP)
sed -i "s|SVC_ID|$SVC_ID|g" ingress.yaml
kubectl apply -f ingress.yaml


# Fluent bit
aws eks create-addon --cluster-name skills-eks-cluster --addon-name eks-pod-identity-agent > /dev/null

ES_ARN=$(aws opensearch describe-domain --domain-name skills-opensearch-domain  --query "DomainStatus.ARN" --output text)

cat <<EOF> es-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:ESHttp*"
            ],
            "Resource": "${ES_ARN}",
            "Effect": "Allow"
        }
    ]
}
EOF

aws iam create-policy --policy-name es-policy --policy-document file://es-policy.json > /dev/null

CLUSTER_OIDC=$(aws eks describe-cluster --name skills-eks-cluster --query "cluster.identity.oidc.issuer" --output text | cut -c 9-100)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

cat <<EOF> trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$CLUSTER_OIDC"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
		                "$CLUSTER_OIDC:sub": "system:serviceaccount:default:fluent-bit",
                    "$CLUSTER_OIDC:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name es-role --assume-role-policy-document file://trust-policy.json > /dev/null

aws iam attach-role-policy --role-name es-role --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/es-policy

ROLE_ARN=$(aws iam get-role --role-name es-role --query "Role.Arn" --output text)
sed -i "s|ROLE_ARN|$ROLE_ARN|g" fluent-bit-sa.yaml
kubectl apply -f fluent-bit-sa.yaml
kubectl apply -f fluent-bit-rbac.yaml
kubectl apply -f cm.yaml

ES_EP=$(aws opensearch describe-domain  --domain-name skills-opensearch-domain --query "DomainStatus.Endpoint" --output text)
TIME=$(date -d "+9 hour" "+%Y.%m.%d")
sed -i "s|ES_EP|$ES_EP|g" daemonset.yaml
sed -i "s|TIME|$TIME|g" daemonset.yaml
kubectl apply -f daemonset.yaml


# Container Insights 
NODEGROUP_ROLE_NAME=$(aws eks describe-nodegroup --cluster-name skills-eks-cluster --nodegroup-name skills-eks-app-nodegroup --query "nodegroup.nodeRole" --output text | cut -d'/' -f2-)

aws iam attach-role-policy \
  --role-name $NODEGROUP_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

aws iam attach-role-policy \
  --role-name $NODEGROUP_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess

aws eks create-addon --cluster-name skills-eks-cluster --addon-name amazon-cloudwatch-observability > /dev/null