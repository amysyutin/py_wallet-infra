# Terraform — py_wallet AWS

AWS infrastructure for py_wallet: VPC, EC2, RDS PostgreSQL, and remote state.

## Architecture

```
Internet
   │
   ▼
┌─────────────────────────────────────────┐
│  VPC (dev: 10.20.0.0/16)                │
│                                         │
│  Public subnets (2 AZ)                  │
│    └─ EC2 (SSH from my_ip/32)           │
│                                         │
│  Private subnets (2 AZ)                 │
│    └─ RDS PostgreSQL (SG → EC2 SG only) │
└─────────────────────────────────────────┘

State: S3 (pywallet-dev-tfstate) + DynamoDB lock
```

## Layout

| Path | Role |
|------|------|
| `bootstrap/` | S3 + DynamoDB for remote state (apply once) |
| `modules/network` | VPC, IGW, public/private subnets, route tables |
| `modules/ec2` | EC2 instance |
| `modules/rds` | PostgreSQL + SG-to-SG + random password |
| `envs/dev` | Root module, remote state `envs/dev/...` |
| `envs/stage` | Root module, remote state `envs/stage/...` |

## Prerequisites

- Terraform `>= 1.6`
- AWS CLI profile `pywallet-dev`
- EC2 key pair in AWS
- `my_ip_cidr` in `terraform.tfvars` (never commit real tfvars)

## Bootstrap (once)

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

## Dev lifecycle

```bash
cd terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars   # set your my_ip_cidr
terraform init
terraform plan
terraform apply
terraform destroy
```

## Stage

```bash
cd terraform/envs/stage
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Use a different VPC CIDR than `dev` if both environments run at the same time.

## CI

GitHub Actions (`.github/workflows/terraform-ci.yml`):

- `terraform fmt -check`
- `terraform init -backend=false` + `validate` (matrix: `dev`, `stage`)
- `tflint`
- `checkov` (`soft_fail: true`)

## Local tooling

```bash
pre-commit install
pre-commit run --all-files
```

Requires `tflint` on `PATH` for the local tflint hook.

## Security notes

- SSH only from `my_ip_cidr` `/32`
- RDS: `publicly_accessible = false`, access via SG → SG
- State encrypted in S3; secrets in state are not masked by `sensitive` alone
- RDS is configured for cheap ephemeral environments (`backup_retention_period = 0`, `skip_final_snapshot = true`, `deletion_protection = false`); tighten these for long-lived deployments
