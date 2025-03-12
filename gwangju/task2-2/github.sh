# GitHub repository URL
GITHUB_REPO_URL="https://github.com/wlstmd/gwangju-application-repo.git"

# GitHub Personal Access Token
GITHUB_USERNAME="wlstmd"
GITHUB_TOKEN="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"

# Add GitHub repository to ArgoCD
argocd repo add $GITHUB_REPO_URL --username $GITHUB_USERNAME --password $GITHUB_TOKEN

# EKS Cluster ARN
EKS_CLUSTER_ARN=$(aws eks describe-cluster --name gwangju-eks-cluster --query "cluster.arn" --output text)

echo y | argocd cluster add $EKS_CLUSTER_ARN

# ECR Repository URI
ECR_REPO_URI=$(aws ecr describe-repositories --query "repositories[?repositoryName=='gwangju-repo'].repositoryUri" --output text)

# Create ArgoCD application
argocd app create py-app \
    --repo $GITHUB_REPO_URL \
    --path . \
    --self-heal \
    --sync-policy automated \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace app \
    --annotations argocd-image-updater.argoproj.io/image-list=org/app=$ECR_REPO_URI \
    --annotations argocd-image-updater.argoproj.io/org_app.pull-secret=ext:/scripts/auth1.sh \
    --annotations argocd-image-updater.argoproj.io/org_app.update-strategy=latest \
    --upsert