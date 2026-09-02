output "verification_status" {
  description = "Cosign verification result"
  value       = data.external.cosign_verify.result
}