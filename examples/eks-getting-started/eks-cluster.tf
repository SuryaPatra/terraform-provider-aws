#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "pilot-cluster-IAM" {
  name = "pilot-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "pilot-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.pilot-cluster-IAM.name
}

resource "aws_iam_role_policy_attachment" "pilot-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.pilot-cluster-IAM.name
}

resource "aws_security_group" "pilot-cluster-SG" {
  name        = "pilot-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.pilot-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pilot-eks-cluster"
  }
}

resource "aws_security_group_rule" "pilot-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.pilot-cluster-SG.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "pilot-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.pilot-cluster-IAM.arn
  enabled_cluster_log_types = ["api", "audit", "scheduler"]

  vpc_config {
    security_group_ids = [aws_security_group.pilot-cluster-SG.id]
    subnet_ids         = aws_subnet.pilot[*].id
    endpoint_public_access = "false"
  }

  depends_on = [
    aws_iam_role_policy_attachment.pilot-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.pilot-cluster-AmazonEKSServicePolicy,
  ]
}
