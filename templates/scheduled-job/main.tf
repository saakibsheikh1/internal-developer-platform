module "scheduled_job" {
  source = "../../modules/scheduled-job"

  job_name            = var.job_name
  team_name           = var.team_name
  environment         = var.environment
  docker_image        = var.docker_image
  aws_region          = var.aws_region
  vpc_id              = var.vpc_id
  private_subnet_ids  = var.private_subnet_ids
  schedule_expression = var.schedule_expression
  cpu                 = var.cpu
  memory              = var.memory
}