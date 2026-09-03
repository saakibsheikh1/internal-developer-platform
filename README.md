# Internal Developer Platform (IDP)

A production-oriented Internal Developer Platform (IDP) that provides self-service application onboarding, reusable golden-path templates, automated AWS provisioning, service catalogue management, image-signature enforcement, governance, observability, adoption metrics, and platform engineering reporting.

---

## 📌 Project Overview

This project implements an Internal Developer Platform that enables development teams to onboard and manage services through standardized golden paths instead of manually provisioning infrastructure.

The platform supports three service templates:

- `web-service`
- `background-worker`
- `scheduled-job`

The platform automates:

- Application onboarding
- AWS infrastructure provisioning
- Container image validation
- Cosign image-signature verification
- ECS/Fargate deployment
- Load balancing
- Queue-based worker processing
- Scheduled workloads
- CloudWatch monitoring
- SNS alerting
- Service catalogue registration
- TechDocs generation
- Golden-path governance
- Template version management
- GitHub Actions automation
- Idempotent deployments
- Offboarding
- Platform adoption metrics
- Catalogue completeness monitoring
- Unregistered-service detection
- Platform engineering reporting

---

# 🏗️ Architecture

```text
                         ┌─────────────────────────┐
                         │       Developers        │
                         └────────────┬────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────┐
                         │   platform.yaml         │
                         │ Service configuration   │
                         └────────────┬────────────┘
                                      │
                                      ▼
                    ┌──────────────────────────────────┐
                    │        GitHub Actions             │
                    │     Automated Onboarding          │
                    └───────────────┬──────────────────┘
                                    │
              ┌─────────────────────┼──────────────────────┐
              │                     │                      │
              ▼                     ▼                      ▼
       ┌─────────────┐      ┌──────────────┐      ┌──────────────┐
       │ Cosign      │      │ Golden Path  │      │ Terraform    │
       │ Verification│      │ Governance   │      │ Provisioning │
       └─────────────┘      └──────────────┘      └───────┬──────┘
                                                          │
                                                          ▼
                                              ┌─────────────────────┐
                                              │        AWS          │
                                              │                     │
                                              │ VPC / ECS / ALB     │
                                              │ SQS / Lambda        │
                                              │ EventBridge         │
                                              │ CloudWatch / SNS    │
                                              │ Route53             │
                                              └──────────┬──────────┘
                                                         │
                    ┌────────────────────────────────────┼────────────────────────┐
                    │                                    │                        │
                    ▼                                    ▼                        ▼
          ┌──────────────────┐                 ┌─────────────────┐      ┌──────────────────┐
          │ Service Catalogue│                 │ CloudWatch      │      │ Platform Metrics │
          │ + TechDocs       │                 │ Dashboard       │      │ Lambda           │
          └──────────────────┘                 └─────────────────┘      └────────┬─────────┘
                                                                                  │
                                                                                  ▼
                                                                         ┌─────────────────┐
                                                                         │ SNS Alerts      │
                                                                         └─────────────────┘
🎯 Platform Goals

The platform is designed around the following principles:

Self-service
Golden paths
Infrastructure as Code
Security by default
Immutable container images
Automated governance
Idempotent deployments
Observable workloads
Catalogue-as-code
Automated offboarding
Platform adoption measurement
📂 Repository Structure
internal-developer-platform/
│
├── .github/
│   └── workflows/
│       └── platform-onboarding.yml
│
├── adoption-dashboard/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lambda_function.py
│   ├── dashboard.json
│   ├── terraform.tfvars
│   └── catalogue-data/
│       └── services.json
│
├── catalogue/
│   └── backstage/
│       ├── app.py
│       ├── requirements.txt
│       ├── payment-api/
│       │   └── catalog-info.yaml
│       ├── order-processor/
│       │   └── catalog-info.yaml
│       └── inventory-sync/
│           └── catalog-info.yaml
│
├── docs/
│   ├── payment-api/
│   │   └── index.md
│   └── platform-engineering-report.md
│
├── governance/
│   ├── template-versions.yaml
│   ├── verify-image-signature.ps1
│   └── orphan-detection/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── lambda_function.py
│
├── modules/
│   ├── ecr/
│   ├── network/
│   ├── ecs-service/
│   ├── background-worker/
│   ├── scheduled-job/
│   ├── monitoring/
│   └── image-signature/
│
├── onboarding/
│   ├── examples/
│   │   └── platform.yaml
│   └── schemas/
│       └── platform.schema.json
│
├── templates/
│   ├── web-service/
│   ├── background-worker/
│   └── scheduled-job/
│
├── github-actions-service-provisioning-policy.json
├── cosign.pub
├── .gitignore
└── README.md
🚀 Supported Golden Paths
1. Web Service

The web-service template provisions an ECS Fargate web application.

Components
Amazon ECS
AWS Fargate
Application Load Balancer
Target Group
Listener
Security Groups
CloudWatch Logs
CloudWatch Alarms
SNS notifications
Route53 integration
Prometheus ServiceMonitor configuration
Naming

Example:

payment-api-dev-cluster
payment-api-dev-service
payment-api-dev-alb
payment-api-dev-target-group
2. Background Worker

The background-worker template provisions asynchronous workers.

Components
Amazon ECS
AWS Fargate
Amazon SQS
Dead Letter Queue
Queue-depth autoscaling
CloudWatch Logs
CloudWatch Alarms
SNS notifications
Example
order-processor-dev

The worker scales based on queue depth and failed messages are routed to the DLQ.

3. Scheduled Job

The scheduled-job template provisions scheduled workloads.

Components
Amazon EventBridge Scheduler
AWS Lambda
Dead Letter Queue
CloudWatch Logs
Execution history logging
SNS notifications
Example
inventory-sync-dev
🔐 Container Image Security

Container images are required to be cryptographically signed using Cosign.

The platform verifies the image signature before Terraform provisions the service.

Image verification flow
Docker Image
     │
     ▼
ECR
     │
     ▼
Cosign Signature Verification
     │
     ├── ❌ Unsigned → Deployment rejected
     │
     └── ✅ Signed → Deployment allowed

Example verification:

C:\cosign\cosign.exe verify `
  --key .\cosign.pub `
  495278513365.dkr.ecr.ap-south-1.amazonaws.com/payment-api@sha256:<DIGEST>

Unsigned images are intentionally rejected by the platform.

🔑 AWS Authentication

GitHub Actions uses AWS IAM OIDC authentication.

The workflow assumes:

IDP-GitHubActions-Onboarding

No long-lived AWS access keys are stored in GitHub Actions.

The role provides the permissions required for:

Terraform infrastructure provisioning
ECS
EC2 networking
IAM execution roles
ALB
CloudWatch
SNS
Route53
Platform failure metrics
⚙️ Automated Onboarding

The primary developer input is:

onboarding/examples/platform.yaml

Example:

service_name: payment-api
template_type: web-service
template_version: "1.0.0"
team_name: payments
docker_image: 495278513365.dkr.ecr.ap-south-1.amazonaws.com/payment-api:1.0.1
environment: dev

The onboarding workflow:

Reads platform.yaml
Validates the schema
Validates the template type
Validates the template version
Checks approved golden-path governance
Verifies the ECR image digest
Verifies the Cosign signature
Bootstraps the platform network when required
Selects the requested template
Generates Terraform variables
Initializes Terraform
Uses a dedicated remote state path
Applies the infrastructure
Registers the service in the catalogue
Generates TechDocs
Generates Grafana dashboard definitions
Publishes an onboarding summary
Records platform metrics
🧩 Template Version Governance

Approved versions are managed in:

governance/template-versions.yaml

Current approved templates:

web-service:
  version: "1.0.0"

background-worker:
  version: "1.0.0"

scheduled-job:
  version: "1.0.0"

The workflow rejects:

Unknown template types
Unapproved templates
Version mismatches
Invalid semantic versions
Incorrect template paths

This prevents developers from silently deploying unsupported platform versions.

🔁 Idempotency

The onboarding workflow is designed to be idempotent.

Running the same configuration again does not recreate unchanged infrastructure.

Terraform reports:

No changes. Your infrastructure matches the configuration.

This allows developers to safely rerun onboarding without introducing duplicate resources.

🗑️ Offboarding

The same GitHub Actions workflow supports:

action: destroy

The destroy operation removes infrastructure associated with the service using the dedicated Terraform state.

This provides a controlled offboarding path instead of requiring developers to manually delete AWS resources.

📚 Service Catalogue

The platform includes a lightweight catalogue implementation compatible with the expected Backstage-style catalogue model.

Registered services include:

payment-api
order-processor
inventory-sync

Each service contains metadata such as:

Service name
Owner/team
Type
Lifecycle
Deployment status
Template
Template version
Runbook
Grafana dashboard
TechDocs
AWS/ECS metadata
📖 TechDocs

Service documentation is maintained as code.

Example:

docs/payment-api/index.md

Documentation covers:

Architecture
Dependencies
Deployment
Monitoring
Troubleshooting
Runbook information
Operational ownership
🔎 Orphan Detection

The platform periodically checks ECS services against the service catalogue.

The system detects services that exist in AWS but are not registered in the catalogue.

Example detected service:

payment-api-dev-service
Team: payments
Environment: dev

An unregistered service produces:

UnregisteredServices > 0

and triggers an SNS notification.

This provides catalogue governance and prevents unmanaged infrastructure.

📊 Adoption Dashboard

The adoption-dashboard Terraform stack creates the platform metrics infrastructure.

Components
AWS Lambda
Amazon CloudWatch
CloudWatch Dashboard
CloudWatch Alarms
Amazon SNS
EventBridge scheduled execution
S3 catalogue data
IAM roles and policies

The metrics namespace is:

IDP/Platform
📈 Platform Metrics

The platform calculates:

Services
ServicesOnboardedCumulative
ServicesOnboardedPerWeek
Template usage
TemplateUsage

Tracks:

web-service
background-worker
scheduled-job
Template versions
TemplateVersionDistribution
Deployment frequency
DeploymentsPerDay
Deployment duration
AverageTimeToDeploy
TimeToDeployP50
TimeToDeployP99
Golden Path compliance
GoldenPathComplianceRate
Catalogue completeness
CatalogueCompletenessRate
Governance
UnregisteredServices
OnboardingPipelineFailure
📊 Current Platform Metrics

The latest platform metrics execution reported:

Services onboarded: 3

Template usage:
  web-service:       1
  background-worker: 1
  scheduled-job:     1

Template version:
  1.0.0: 3

Team usage:
  payments:  2
  inventory: 1

Golden Path compliance: 100%

Catalogue completeness: 100%

Unregistered services: 1

Current deployment timing data:

web-service:
  Average: 272 seconds
  P50:     272 seconds
  P99:     272 seconds

background-worker:
  Average: 375 seconds
  P50:     375 seconds
  P99:     375 seconds

scheduled-job:
  Average: 228 seconds
  P50:     228 seconds
  P99:     228 seconds

The Lambda also tracks calendar-week onboarding and daily deployment counts.

🚨 Platform Alerts

The platform provides CloudWatch alarms for:

Onboarding Pipeline Failure

Metric:

OnboardingPipelineFailure

A failed onboarding pipeline generates an SNS notification containing:

Service name
Team
Template
Template version
Failure step
Environment
Unregistered Service

Metric:

UnregisteredServices

An SNS notification identifies:

ECS service
Team tag
Environment
Cluster
Golden Path Compliance

Metric:

GoldenPathComplianceRate

An alarm is configured when compliance drops below:

90%
☁️ CloudWatch Dashboard

The platform dashboard is:

IDP-Platform-Health

The dashboard contains:

Services onboarded cumulative
Services onboarded per week
Deployments per day
Average deployment time
Deployment time P50
Deployment time P99
Golden Path compliance
Catalogue completeness
Template usage
Template version distribution
Unregistered services
Onboarding pipeline failures
📨 SNS Notifications

Platform alerts are delivered through:

idp-platform-alerts

The onboarding summary uses SNS notifications to communicate deployment results.

The platform therefore provides both:

Operational alerts

and

Onboarding summaries
🗄️ Terraform State

Terraform state is stored remotely in Amazon S3.

The platform uses dedicated state paths under:

idp-onboarding/

Examples:

idp-onboarding/platform-bootstrap/terraform.tfstate
idp-onboarding/dev/payment-api/terraform.tfstate
idp-onboarding/adoption-dashboard/terraform.tfstate

S3 state locking uses Terraform's native S3 lockfile mechanism.

Existing unrelated Terraform states are not modified.

🧪 Validation & Testing

The platform has been tested through the following scenarios.

Schema Validation

Invalid or missing platform configuration fields are rejected.

Required fields include:

service_name
template_type
template_version
team_name
docker_image
environment
Image Signature Test
Unsigned image

Expected result:

IMAGE SIGNATURE VERIFICATION FAILED

Deployment is rejected.

Signed image

Expected result:

Cosign verification successful

Deployment proceeds.

Idempotency Test

Running the same onboarding configuration again results in:

No changes.
Your infrastructure matches the configuration.
Offboarding Test

Destroy workflow successfully removes service infrastructure.

Orphan Detection Test

An unregistered ECS service was detected and generated an alert.

Platform Metrics Test

The metrics Lambda successfully returned:

StatusCode: 200

and calculated the platform metrics successfully.

GitHub Actions Test

The latest onboarding workflow completed successfully.

Example execution:

Validate platform configuration
        ↓
Bootstrap platform network
        ↓
Onboard service
        ↓
Success

The successful workflow completed in approximately:

2 minutes 28 seconds
🔐 Security Controls

The platform follows security-by-default principles.

Implemented controls include:

GitHub OIDC authentication
No long-lived AWS credentials in GitHub Actions
Cosign image-signature verification
Immutable ECR repositories
ECR image scanning
IAM-controlled AWS access
Terraform remote state
Encrypted S3 state
Private ECS networking
CloudWatch logging
CloudWatch alarms
SNS security notifications
Golden-path version governance
🏷️ Resource Tagging

Platform-managed resources use standardized tags.

Example:

Team        = payments
Environment = dev
ManagedBy   = IDP

This enables:

Ownership tracking
Cost allocation
Resource discovery
Governance
Unregistered-service detection
🛠️ Local Development
Prerequisites

Install:

Git
Terraform
AWS CLI
Docker
Python
Cosign

Verify:

git --version
terraform version
aws --version
docker --version
python --version
cosign version
🔑 AWS Configuration

Configure AWS CLI:

aws configure

Verify:

aws sts get-caller-identity

The project is configured for:

Region: ap-south-1
🐍 Catalogue Development

Install dependencies:

cd catalogue/backstage
pip install -r requirements.txt

Run the catalogue:

python app.py

The catalogue can then be accessed through the local Flask application.

🧮 Platform Metrics Development

Navigate to:

adoption-dashboard/

Validate Terraform:

terraform init
terraform validate
terraform plan

The metrics Lambda can be tested directly:

aws lambda invoke `
  --function-name idp-platform-metrics `
  --region ap-south-1 `
  --payload '{}' `
  .\lambda-response.json

Inspect the result:

Get-Content .\lambda-response.json
🏗️ Terraform Workflow

For a Terraform stack:

terraform init
terraform validate
terraform plan
terraform apply

For controlled removal:

terraform destroy

Always verify the Terraform state and target environment before executing destroy.

🔄 GitHub Actions Workflow

The main automation workflow is:

.github/workflows/platform-onboarding.yml

The workflow is responsible for:

Configuration validation
        ↓
Golden-path governance
        ↓
Image digest validation
        ↓
Cosign verification
        ↓
Network bootstrap
        ↓
Terraform provisioning
        ↓
Catalogue registration
        ↓
TechDocs generation
        ↓
Grafana definition
        ↓
SNS summary
        ↓
Platform metrics
📄 Platform Configuration

Example:

service_name: payment-api
template_type: web-service
template_version: "1.0.0"
team_name: payments
docker_image: 495278513365.dkr.ecr.ap-south-1.amazonaws.com/payment-api:1.0.1
environment: dev

The platform configuration is intentionally small so developers do not need to understand the underlying AWS infrastructure.

🧭 Developer Experience

A developer only needs to provide:

Service name
Template
Template version
Team
Container image
Environment

The platform handles the rest.

This creates a standardized path from:

Application
    ↓
Configuration
    ↓
Validation
    ↓
Security verification
    ↓
Infrastructure
    ↓
Deployment
    ↓
Catalogue
    ↓
Observability
    ↓
Governance
📋 Golden Path Checklist

Every managed service should have:

 Approved template
 Approved template version
 Valid platform.yaml
 Signed container image
 Terraform-managed infrastructure
 Standard resource tags
 CloudWatch monitoring
 SNS alerting
 Service catalogue entry
 Owner/team
 Runbook
 Dashboard definition
 TechDocs
 Deployment status
 Offboarding path
📊 Platform Engineering Reporting

The platform engineering report is maintained at:

docs/platform-engineering-report.md

The report covers:

Total services managed
Onboarding performance
Golden Path compliance
Template adoption
Team adoption
Catalogue completeness
Deployment performance
Onboarding failure reasons
Platform governance
⚠️ Grafana Note

The project generates Grafana dashboard definitions and dashboard metadata as part of onboarding.

The current implementation does not depend on a live Grafana server.

Dashboard definitions are stored under:

monitoring/grafana/

A production Grafana deployment can consume these definitions later.

🧹 Resource Cleanup

The assignment requires temporary AWS resources to be removed after review.

Before cleanup, verify:

aws ecs list-clusters --region ap-south-1
aws ecr describe-repositories --region ap-south-1
aws lambda list-functions --region ap-south-1
aws cloudwatch list-dashboards --region ap-south-1
aws sns list-topics --region ap-south-1

Terraform-managed resources should be removed through Terraform where applicable:

terraform destroy

Do not delete shared or unrelated infrastructure.

🧾 Evidence

Recommended evidence for project review:

Stage 1
Template provisioning
ECS service
ALB
Worker/SQS
Scheduled Lambda
Signed image
Unsigned image rejection
Stage 2
Catalogue
Service registrations
TechDocs
Orphan detection
Stage 3
GitHub Actions onboarding
Terraform apply
Idempotency
Offboarding
Stage 4
Template version governance
Approved version validation
Golden-path controls
Stage 5
CloudWatch dashboard
Metrics Lambda output
CloudWatch alarms
SNS configuration
Successful GitHub Actions onboarding
Platform engineering report

Sensitive information such as:

AWS account IDs
Email addresses
Access tokens
Secrets
Private keys

should be masked in screenshots.

📈 Project Outcome

The completed Internal Developer Platform provides a standardized and automated developer experience for application onboarding.

The platform demonstrates:

Self-Service
     +
Golden Paths
     +
Infrastructure as Code
     +
Security
     +
Automation
     +
Governance
     +
Observability
     +
Service Catalogue
     +
Adoption Metrics

This reduces manual infrastructure work while improving consistency, security, ownership, and operational visibility across platform-managed services.

👨‍💻 Project

Internal Developer Platform

Owner: Sakib Sheikh

AWS Region: ap-south-1

Primary Infrastructure: AWS

Infrastructure as Code: Terraform

CI/CD: GitHub Actions

Container Platform: Amazon ECS / AWS Fargate

Container Registry: Amazon ECR

Security: Cosign

Monitoring: Amazon CloudWatch

Notifications: Amazon SNS

Scheduling: Amazon EventBridge

Service Catalogue: Lightweight Backstage-compatible catalogue

Documentation: Markdown / TechDocs

✅ Final Status
Stage 1  - Self-Service Templates       COMPLETE
Stage 2  - Service Catalogue            COMPLETE
Stage 3  - Automated Onboarding         COMPLETE
Stage 4  - Governance & Golden Paths    COMPLETE
Stage 5  - Adoption & Platform Metrics  COMPLETE
Internal Developer Platform — COMPLETE
