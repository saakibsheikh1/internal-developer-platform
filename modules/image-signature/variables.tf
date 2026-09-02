variable "docker_image" {
  description = "Container image that must have a valid Cosign signature"
  type        = string
}

variable "public_key_path" {
  description = "Path to the Cosign public key"
  type        = string
}

variable "powershell_command" {
  description = "PowerShell executable used for Cosign verification"
  type        = string
  default     = null
}
