param(
    [Parameter(Mandatory = $true)]
    [string]$Image,

    [Parameter(Mandatory = $true)]
    [string]$PublicKey
)

$ErrorActionPreference = "Continue"

# Run Cosign verification.
# Capture stdout and stderr so PowerShell does not convert native output
# into a terminating Terraform execution error.
$cosignOutput = & cosign verify --key $PublicKey $Image 2>&1
$cosignExitCode = $LASTEXITCODE

if ($cosignExitCode -ne 0) {
    [Console]::Error.WriteLine(
        "IMAGE SIGNATURE VERIFICATION FAILED: $Image"
    )

    foreach ($line in $cosignOutput) {
        [Console]::Error.WriteLine($line.ToString())
    }

    exit 1
}

# Terraform external data source requires stdout to be
# a JSON object containing string keys and string values.
Write-Output '{"verified":"true"}'

exit 0