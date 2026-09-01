# ============================================================
# ECR Repository
# ============================================================

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.service_name
  team_name       = var.team_name
  environment     = var.environment
}
# ============================================================
# Network Module
# ============================================================

module "network" {
  source = "./modules/network"

  name        = var.service_name
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# ============================================================
# ECS Fargate Web Service Module
# ============================================================

module "web_service" {
  source = "./modules/ecs-service"

  service_name = var.service_name
  team_name    = var.team_name
  environment  = var.environment
  docker_image = var.docker_image

  aws_region = var.aws_region

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  container_port = var.container_port
  cpu            = var.cpu
  memory         = var.memory
  desired_count  = var.desired_count
}