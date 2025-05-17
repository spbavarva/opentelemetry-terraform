# Added
provider "kubernetes" {
  config_path = "${pathexpand("~/.kube/config")}"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "eks_admin" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_security_group" "open_sg" {
  name        = "eks-client-open"
  description = "Allow all inbound and outbound"
  vpc_id      = aws_vpc.otel_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "eks_client" {
  ami           = "ami-0c101f26f147fa7fd" # Amazon Linux 2 AMI (HVM), SSD Volume Type - replace if needed
  instance_type = "t3.large"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "otel-docker-key"
  iam_instance_profile = aws_iam_instance_profile.eks_admin_instance_profile.name
  vpc_security_group_ids = [aws_security_group.open_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install unzip -y

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Install kubectl
              cat <<EOT | tee /etc/yum.repos.d/kubernetes.repo
              [kubernetes]
              name=Kubernetes
              baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
              enabled=1
              gpgcheck=1
              gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
              EOT

              yum install -y kubectl

              # Install eksctl
              curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
              mv /tmp/eksctl /usr/local/bin

              # Helm
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

              # Mark all binaries available
              hash -r
              EOF

  tags = {
    Name = "eks-client"
  }
}

resource "aws_iam_instance_profile" "eks_admin_instance_profile" {
  name = "eks-admin-profile"
  role = aws_iam_role.eks_admin.name
}

# VPC with public subnet only
resource "aws_vpc" "otel_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.otel_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.otel_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.otel_vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.otel_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "otel-cluster"
  cluster_version = "1.29"
  subnet_ids      =  [aws_subnet.public_subnet.id,aws_subnet.public_subnet_2.id]
  vpc_id          = aws_vpc.otel_vpc.id

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 2
      min_capacity     = 2
      instance_types   = ["t3.large"]
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_admin.arn
      username = "eks-admin"
      groups   = ["system:masters"]
    }
  ]
  providers = {
    kubernetes = kubernetes
    }

}
