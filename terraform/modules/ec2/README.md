# Module: ec2

Creates a single EC2 instance with tags and optional public IP association.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | ~> 5.0 |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for the EC2 instance | `string` | n/a | yes |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Whether to associate a public IP address | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Existing AWS EC2 key pair name | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name tag for the EC2 instance | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs attached to the instance | `list(string)` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID where the instance will be launched | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for the EC2 instance | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | EC2 instance ID |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | EC2 private IP address |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | EC2 public IP address |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID where the instance was launched |
<!-- END_TF_DOCS -->
