# Terraform — py_wallet AWS lab

Учебная AWS-инфраструктура для py_wallet: VPC, EC2, RDS PostgreSQL, remote state.

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
| `envs/stage` | Root module, remote state `envs/stage/...` (plan-only lab) |

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
terraform destroy   # destroy RDS/EC2 when done for the day
```

## Stage

```bash
cd terraform/envs/stage
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
# apply only if you intentionally want a second stack
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
# optional local checks (also run in CI)
pre-commit install
pre-commit run --all-files

# tflint binary (if not on PATH): put in ~/bin
# https://github.com/terraform-linters/tflint/releases
```

## Security notes (lab)

- SSH only from `my_ip_cidr` `/32`
- RDS: `publicly_accessible = false`, access via SG → SG
- State encrypted in S3; passwords live in state (`sensitive` only masks CLI output)
- Some Checkov findings (e.g. `backup_retention_period = 0`, `skip_final_snapshot`) are intentional for a destroy-friendly lab
