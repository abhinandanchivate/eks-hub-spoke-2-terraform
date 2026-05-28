# EKS Hub-Spoke Infrastructure

## Architecture

```
Hub VPC (10.0.0.0/16)
  └── Hub EKS Cluster
        ├── AWS Load Balancer Controller
        ├── Cluster Autoscaler
        └── EBS CSI Driver

Spoke1 VPC (10.1.0.0/16)  <── VPC Peering ──> Hub
  └── Spoke1 EKS Cluster
        ├── PostgreSQL (Helm / Bitnami)
        ├── MongoDB (Helm / Bitnami)
        └── Add-ons (LBC, CA, EBS CSI)

Spoke2 VPC (10.2.0.0/16)  <── VPC Peering ──> Hub
  └── Spoke2 EKS Cluster
        ├── PostgreSQL (Helm / Bitnami)
        ├── MongoDB (Helm / Bitnami)
        └── Add-ons (LBC, CA, EBS CSI)
```

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured
- kubectl
- helm >= 3.x

## Usage

```bash
# 1. Deploy Hub
cd hub && terraform init && terraform apply

# 2. Deploy Spoke1
cd ../spoke1 && terraform init && terraform apply

# 3. Deploy Spoke2
cd ../spoke2 && terraform init && terraform apply

# 4. Setup VPC Peering
cd ../peering && terraform init && terraform apply
```

## Credentials

Never hardcode AWS credentials. Use one of:
- AWS CLI: `aws configure`
- Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- IAM Roles (recommended for CI/CD)
- AWS Vault / SSO
