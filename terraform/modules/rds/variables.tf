variable "name_prefix" {
    description = "Prefix for RDS resource name"
    type = string
}

variable "vpc_id" {
    description = "VPC ID where RDS will be created"
    type = string
}

variable "subnet_ids" {
    description = "Private subnet IDs for the DB subnet group"
    type = list(string)
}

variable "allowed_security_group_id" {
    description = "Security group ID allowed to connect to RDS"
    type = string
}

variable "db_name" {
    description = "Initial PostgreSQL database name"
    type = string
}

variable "username" {
    description = "Master username for PostgreSQL"
    type = string
}

variable "instance_class" {
    description = "RDS instance class"
    type = string
    default = "db.t4g.micro"
}

variable "allocated_storage" {
    description = "Allocated storage in GB"
    type = number
    default = 20
}

variable "tags" {
    description = "Common tags for RDS resources"
    type = map(string)
    default = {}
}