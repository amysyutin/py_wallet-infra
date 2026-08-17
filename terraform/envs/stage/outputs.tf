output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.public_ip
}

output "instance_private_ip" {
  description = "EC2 private IP"
  value       = module.ec2.private_ip
}

output "security_group_id" {
  description = "Security Group ID for EC2 SSH access"
  value       = aws_security_group.ec2_ssh.id
}

output "subnet_id" {
  description = "Subnet ID where EC2 is launched"
  value       = module.ec2.subnet_id
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ~/.ssh/aws/${var.key_name}.pem ubuntu@${module.ec2.public_ip}"
}

output "rds_endpoint" {
  description = "RDS endpoint host:port"
  value       = module.rds.endpoint
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = module.rds.username
}

output "rds_password" {
  description = "RDS master password"
  value       = module.rds.password
  sensitive   = true
}