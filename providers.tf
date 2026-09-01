provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "IDP"
      Project   = "internal-developer-platform"
    }
  }
}