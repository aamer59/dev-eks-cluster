data "aws_caller_identity" "this" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

resource "aws_iam_role" "external_dns" {
  name = "dev-external-dns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:external-dns"
        }
      }
    }
  ]
}
  EOF
  tags = {
    Terraform = "true"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_iam_policy" "external_dns" {
  name        = "external-dns-dev"
  description = "Policy using OIDC to give the EKS external dns ServiceAccount permissions to update Route53"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
  ]
}
EOF
}
