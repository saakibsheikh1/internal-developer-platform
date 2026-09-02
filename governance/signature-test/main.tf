terraform {
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "external" {}

module "image_signature" {
  source = "../../modules/image-signature"

  docker_image    = var.docker_image
  public_key_path = var.public_key_path
}

variable "docker_image" {
  description = "Image to verify"
  type        = string
}

variable "public_key_path" {
  description = "Cosign public key path"
  type        = string
}

output "verification_status" {
  value = module.image_signature.verification_status
}