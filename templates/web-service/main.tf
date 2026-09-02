# ------------------------------------------------------------
# Container Image Signature Verification
# ------------------------------------------------------------

module "image_signature" {
  source = "../../modules/image-signature"

  docker_image    = var.docker_image
  public_key_path = var.cosign_public_key_path
}

# ------------------------------------------------------------
# ECS Fargate Web Service
# ------------------------------------------------------------

module "web_service" {
  source = "../../modules/ecs-service"

  service_name = var.service_name
  team_name    = var.team_name
  environment  = var.environment
  docker_image = var.docker_image

  aws_region = var.aws_region

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids

  container_port = var.container_port
  cpu            = var.cpu
  memory         = var.memory
  desired_count  = var.desired_count

  depends_on = [module.image_signature]
}

# ------------------------------------------------------------
# CloudWatch Monitoring + SNS Alerts
# ------------------------------------------------------------

module "monitoring" {
  source = "../../modules/monitoring"

  service_name = var.service_name
  team_name    = var.team_name
  environment  = var.environment
  alert_email  = var.alert_email

  cluster_name             = module.web_service.ecs_cluster_name
  ecs_service_name         = module.web_service.ecs_service_name
  target_group_arn_suffix  = module.web_service.target_group_arn_suffix
  load_balancer_arn_suffix = module.web_service.load_balancer_arn_suffix
}

# ------------------------------------------------------------
# Optional Route53 DNS Record
# ------------------------------------------------------------

resource "aws_route53_record" "service" {
  count = var.route53_zone_id != null && var.route53_record_name != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = module.web_service.load_balancer_dns_name
    zone_id                = module.web_service.load_balancer_zone_id
    evaluate_target_health = true
  }
}