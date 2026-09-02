module "background_worker" {
  source = "../../modules/background-worker"

  service_name               = var.service_name
  team_name                  = var.team_name
  environment                = var.environment
  docker_image               = var.docker_image
  vpc_id                     = var.vpc_id
  private_subnet_ids         = var.private_subnet_ids
  cpu                        = var.cpu
  memory                     = var.memory
  desired_count              = var.desired_count
  min_capacity               = var.min_capacity
  max_capacity               = var.max_capacity
  queue_name                 = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  max_receive_count          = var.max_receive_count
}