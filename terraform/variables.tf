variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile used for credentials"
  type        = string
  default     = "vscode"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "simple-crud-api"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path the load balancer calls to decide if a task is healthy. Must return 200."
  type        = string
  default     = "/api/v1/locations/"
}

variable "image_tag" {
  description = "Tag of the image in ECR to run. Repository tags are immutable, so use a new tag for every build."
  type        = string
  default     = "v1"
}

variable "desired_count" {
  description = "Number of tasks to run. Keep at 1 while the API uses SQLite, because each task has its own database."
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer. Leave empty to allow only your current public IP, looked up automatically."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "How long CloudWatch keeps the container logs"
  type        = number
  default     = 7
}
