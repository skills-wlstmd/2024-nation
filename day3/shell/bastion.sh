# Cluster
aws eks --region ap-northeast-2 update-kubeconfig --name apdev-eks-cluster

kubectl create ns apdev


# Karpenter
export AWS_REGION=ap-northeast-2
export TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export CLUSTER_NAME=$(eksctl get clusters -o json | jq -r '.[0].Name')
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
export AZ1="$AWS_REGION"a
export AZ2="$AWS_REGION"b

echo Cluster Name:$CLUSTER_NAME AWS Region:$AWS_REGION Account ID:$AWS_ACCOUNT_ID Cluster Endpoint:$CLUSTER_ENDPOINT AZ1:$AZ1 AZ2:$AZ2

TEMPOUT=$(mktemp)

curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.37.1/website/content/en/docs/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "${CLUSTER_NAME}" \
  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes

#oidc 확인
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

# Service account 생성
eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace kube-system \
  --role-name "${CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

#확인
eksctl get iamserviceaccount --cluster $CLUSTER_NAME --namespace kube-system

export KARPENTER_VERSION="v0.37.1"
export KARPENTER_VERSION_STR="${KARPENTER_VERSION/v}"
echo "Karpenter's release version: $KARPENTER_VERSION_STR"


echo Your Karpenter version is: $KARPENTER_VERSION_STR
docker logout public.ecr.aws
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION_STR} --namespace kube-system \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set settings.clusterEndpoint=${CLUSTER_ENDPOINT} \
  --wait
  
#잘못배포 시 아래 명령어를 통해 삭제
# helm uninstall karpenter --namespace {KARPENTER_NAMESPACE}

wget -O eks-node-viewer https://github.com/awslabs/eks-node-viewer/releases/download/v0.6.0/eks-node-viewer_Linux_x86_64
sudo chmod +x eks-node-viewer
sudo mv -v eks-node-viewer /usr/local/bin

eks-node-viewer

export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/bottlerocket/aws-k8s-1.29/x86_64/latest/image_id --region ap-northeast-2 --query "Parameter.Value" --output text)"

cat << EOF > nodespec.yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: apdnodepool
  namespace: app
spec:
  disruption:
    consolidateAfter: 30s
    consolidationPolicy: WhenEmpty
    expireAfter: 2h
  template:
    metadata:
        labels:
         karpenter-node: this
    spec:
      nodeClassRef:
        name: apdnodeclass
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.micro"]

---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: apdnodeclass
  namespace: app
spec:
  tags:
    Name: apdev-app-ng
  amiFamily: Bottlerocket
  role: karpenterNodeRole-$CLUSTER_NAME
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: $CLUSTER_NAME
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: $CLUSTER_NAME
  tags:
    intent: apps
    managed-by: karpenter
  amiSelectorTerms:
    - id: $AMD_AMI_ID
EOF

kubectl apply -f nodespec.yaml


# Employee
IMAGE_URL=$(aws ecr describe-repositories --repository-name apdev-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name apdev-ecr --query "imageDetails[?contains(imageTags, 'employee')].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# Token
IMAGE_URL=$(aws ecr describe-repositories --repository-name apdev-ecr --query "repositories[].repositoryUri" --output text)
IMAGE_TAG=$(aws ecr describe-images --repository-name apdev-ecr --query "imageDetails[?contains(imageTags, 'token')].imageTags" --output text)
IMAGE="$IMAGE_URL:$IMAGE_TAG"
sed -i "s|IMAGE|$IMAGE|g" deployment.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml


# HPA
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f employee.yaml
kubectl apply -f token.yaml

kubectl logs -n kube-system  deploy/karpenter -f
kubectl rollout restart daemonset aws-node -n kube-system

