# OpenTelemetry EKS Project – Post-Terraform Instructions

## Terraform Steps

Clone the remo and run the following commands to deploy the infrastructure:

```bash
terraform init
terraform apply
```

👉 Type "yes" in apply and ignore warnings or errors. Wait till it finishes.


## SSH into EC2 Instance

Once terraform apply is complete, SSH into the eks-client instance using:

ssh -i otel-docker-key ec2-user@<public-ip>

Replace <public-ip> with the EC2 IP. you can find it in the EC2 console and instance name is `eks-client`



## Setup (on EC2)

Run the commands below inside the EC2 instance:

#### Configure AWS CLI

```bash
aws configure
```

#### Create IAM Identity Mapping for EKS

```bash
eksctl create iamidentitymapping   --cluster otel-cluster   --region us-east-1   --arn arn:aws:iam::412134929535:role/eks-admin-role   --group system:masters   --username eks-admin
```

#### Update Kubeconfig to Access the Cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name otel-cluster
kubectl get nodes
```


#### Install Git and Clone Helm Charts

```bash
sudo yum install -y git

git clone https://github.com/open-telemetry/opentelemetry-helm-charts
cd opentelemetry-helm-charts/
```

#### Add OpenTelemetry Helm Repo

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```


#### deploying application

```bash
kubectl create namespace otel-demo
help install opentelemetry-demo open-telemetry/opentelemetry-demo --namespace otel-demo
```