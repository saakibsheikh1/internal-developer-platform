param(
    [Parameter(Mandatory = $true)]
    [string]$Image,

    [Parameter(Mandatory = $true)]
    [string]$PublicKey
)

$ErrorActionPreference = "Stop"

Write-Host "Verifying Cosign signature for: $Image"

& cosign verify --key $PublicKey $Image

if ($LASTEXITCODE -ne 0) {
    Write-Error "IMAGE SIGNATURE VERIFICATION FAILED: $Image"
    exit 1
}

Write-Host "IMAGE SIGNATURE VERIFIED: $Image"
exit 0