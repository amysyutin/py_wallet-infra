variable "name_prefix" {
  description = "Prefix for all network resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subneets, one per AZ"
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all network resources"
  type        = map(string)
  default     = {}
}