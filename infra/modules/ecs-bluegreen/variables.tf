variable "name" { type = string }
variable "region" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "image" {
  type        = string
  description = "ECR repo URL, e.g. 123.dkr.ecr.ap-south-1.amazonaws.com/app"
}
variable "image_tag" {
  type        = string
  description = "Tag to deploy (commit SHA)"
}
variable "container_port" {
  type    = number
  default = 8080
}
variable "health_check_path" {
  type    = string
  default = "/healthz/live"
}
variable "task_cpu" {
  type    = string
  default = "256"
}
variable "task_memory" {
  type    = string
  default = "512"
}
variable "desired_count" {
  type    = number
  default = 2
}
variable "environment" {
  type    = string
  default = "prod"
}
