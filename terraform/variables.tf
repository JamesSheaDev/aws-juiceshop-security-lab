# Input variables for the Juice Shop lab infrastructure

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy all resources into."
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment name (e.g. dev, staging, prod). Used in resource names and tags."
}

variable "owner_tag" {
  type        = string
  default     = "juice-shop-team"
  description = "Value for the Owner tag applied to all resources, for cost attribution and ownership tracking."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
  description = "CIDR blocks for public subnets (one per AZ). The ALB will be placed here."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]
  description = "CIDR blocks for private subnets (one per AZ). ECS Fargate tasks will run here."
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS task replicas to run. Keep at 1 for a dev sandbox to minimize cost."
}

variable "container_image" {
  type        = string
  default     = "bkimminich/juice-shop:latest"
  description = "Docker image to run in the ECS task. Defaults to the official OWASP Juice Shop image."
}

variable "container_port" {
  type        = number
  default     = 3000
  description = "Port the Juice Shop container listens on. The ALB target group and security groups will use this value."
}

variable "tags" {
  type        = map(string)
  default     = { project = "juice-shop-lab" }
  description = "Map of additional tags to apply to all resources. Merged with per-resource tags at deploy time."
}

variable "task_cpu" {
  type        = number
  default     = 256
  description = "CPU units for the ECS Fargate task (256 = 0.25 vCPU). Valid Fargate values: 256, 512, 1024, 2048, 4096."
}

variable "task_memory" {
  type        = number
  default     = 512
  description = "Memory (MiB) for the ECS Fargate task. Must be a valid combination with task_cpu."
}

variable "log_retention_days" {
  type        = number
  default     = 30
  description = "CloudWatch log group retention in days."
}

variable "alb_ingress_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed inbound to the ALB on port 80. Restrict in Phase 5 hardening."
}
