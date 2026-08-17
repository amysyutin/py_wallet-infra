output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets in AZ order"
  value       = [for az in var.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets in AZ order"
  value       = [for az in var.azs : aws_subnet.private[az].id]
}

output "azs" {
  description = "Availability zones used by this network"
  value       = var.azs
}

