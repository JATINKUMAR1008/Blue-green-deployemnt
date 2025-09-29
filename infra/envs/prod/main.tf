terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
  backend "s3" {
    bucket  = "tf-state-bucket-1001"
    key     = "ecs-bluegreen/prod/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

provider "aws" { region = var.region }

locals { name = "shopapi" }

module "network" {
  source   = "../../modules/network"
  name     = local.name
  region   = var.region
  vpc_cidr = var.vpc_cidr
}

module "ecr" {
  source = "../../modules/ecr"
  name   = local.name
}

module "oidc" {
  source      = "../../modules/iam-oidc"
  name        = local.name
  github_repo = var.github_repo
}

module "ecs" {
  source         = "../../modules/ecs-bluegreen"
  name           = local.name
  region         = var.region
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.public_subnet_ids
  image          = module.ecr.repository_url
  image_tag      = var.image_tag
  container_port = var.container_port
  desired_count  = var.desired_count
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory
  environment    = "prod"
}

# output "alb_dns"             { value = module.ecs.alb_dns_name }
# output "github_oidc_role_arn"{ value = module.oidc.role_arn }
# output "ecr_repo"            { value = module.ecr.repository_url }
# output "cluster_name"        { value = module.ecs.cluster_name }
# output "service_name"        { value = module.ecs.service_name }
# output "task_family"         { value = module.ecs.task_family }
# output "cd_app"              { value = module.ecs.cd_app }
# output "cd_group"            { value = module.ecs.cd_group }
# output "listener_arn"        { value = module.ecs.listener_arn }
# output "tg_blue_arn"         { value = module.ecs.tg_blue_arn }
# output "tg_green_arn"        { value = module.ecs.tg_green_arn }
