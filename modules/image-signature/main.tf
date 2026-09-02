locals {
  powershell_command = var.powershell_command != null ? var.powershell_command : (
    substr(abspath(path.root), 0, 1) == "/" ? "pwsh" : "powershell"
  )
}

data "external" "cosign_verify" {
  program = [
    local.powershell_command,
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    "${path.module}/../../governance/verify-image-signature.ps1",
    "-Image",
    var.docker_image,
    "-PublicKey",
    var.public_key_path
  ]
}

resource "terraform_data" "signature_verified" {
  input = data.external.cosign_verify.result
}
