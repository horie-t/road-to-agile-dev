variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "todo-manager"
}

variable "env" {
  description = "Environment name (e.g., dev, stg, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "ECS service desired task count"
  type        = number
  default     = 1
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}

# GitHub Actions OIDC / IAM Role settings
variable "enable_github_oidc" {
  description = "Enable creation of GitHub OIDC provider and IAM role for Actions to push to ECR"
  type        = bool
  default     = true
}

variable "github_oidc_subjects" {
  description = <<EOT
List of allowed GitHub OIDC subjects (StringLike patterns) that can assume the role.
Examples:
  - "repo:OWNER/REPO:ref:refs/heads/main"           # only main branch
  - "repo:OWNER/REPO:environment:prod"              # GitHub Environments
  - "repo:OWNER/REPO:*"                              # any ref in the repository
EOT
  type    = list(string)
  # NOTE: Replace OWNER/REPO accordingly. This placeholder blocks real use until you set it.
  default = ["repo:OWNER/REPO:*"]
}
