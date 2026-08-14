variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "pywallet-dev"
}

variable "project" {
  description = "Project name used in resource name"
  type        = string
  default     = "pywallet"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}