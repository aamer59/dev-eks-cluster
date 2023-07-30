1. aws iam create-policy --policy-name "AllowExternalDNSUpdates" --policy-document file://policy.json

# myoutput: arn:aws:iam::140554438763:policy/AllowExternalDNSUpdates
2. export POLICY_ARN=$(aws iam list-policies \
 --query 'Policies[?PolicyName==`AllowExternalDNSUpdates`].Arn' --output text)

export EKS_CLUSTER_NAME="abyaz"
export EKS_CLUSTER_REGION="ap-south-2"
export KUBECONFIG="$HOME/.kube/${EKS_CLUSTER_NAME}-${EKS_CLUSTER_REGION}.yaml"

aws eks describe-cluster --name $EKS_CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text
eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve
eksctl create iamserviceaccount --cluster $EKS_CLUSTER_NAME --name "external-dns" --namespace ${EXTERNALDNS_NS:-"default"} --attach-policy-arn $POLICY_ARN --approve

k apply -f manifest.yaml