variable "aws_region" {
  description = "The AWS region to deploy the resources in."
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "project name (used as resource prefix)"
  type        = string
  default     = "konnichiwa"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks list for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks list for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "container_port" {
  description = "port container listens on."
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "The CPU units to allocate to the container."
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The memory (in MiB) to allocate to the container."
  type        = number
  default     = 512
}

variable "app_count" {
  description = "The desired number of tasks to run for the service."
  type        = number
  default     = 2
}
variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "min_capacity" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 1
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}
