data "external" "cosign_verify" {
  program = [
    "powershell",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    "${path.root}/governance/verify-image-signature.ps1",
    "-Image",
    var.docker_image,
    "-PublicKey",
    var.public_key_path
  ]
}

resource "terraform_data" "signature_verified" {
  input = data.external.cosign_verify.result
}