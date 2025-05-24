variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "vockey"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "notes-app"
}

variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/jahichka/iso-projekt"
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  default     = "dbuser"
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  default     = "password123"
  sensitive   = true
}