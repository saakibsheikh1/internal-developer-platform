module "image_signature" {
  source = "../../modules/image-signature"

  docker_image    = var.docker_image
  public_key_path = var.cosign_public_key_path
}

module "web_service" {
  source = "../../modules/ecs-service"

  service_name       = var.service_name
  team_name          = var.team_name
  environment        = var.environment
  docker_image       = var.docker_image
  aws_region         = var.aws_region
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
  container_port     = var.container_port
  cpu                = var.cpu
  memory             = var.memory
  desired_count      = var.desired_count

  depends_on = [module.image_signature]
}