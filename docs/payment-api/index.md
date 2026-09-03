# payment-api

## Service Overview

- **Service:** payment-api
- **Owner:** payments
- **Environment:** dev
- **Template:** web-service
- **Template Version:** 1.0.0

## Platform

This service was provisioned through the Internal Developer Platform.

## Golden Path Governance

The service uses the approved golden-path template version
1.0.0.

## Infrastructure

Terraform infrastructure is provisioned through the selected
golden-path template.

## Terraform State

`idp-onboarding/dev/payment-api/terraform.tfstate`

## Monitoring

Grafana dashboard:

https://grafana.example.com/d/payment-api

## Runbook

1. Check ECS service health.
2. Check CloudWatch alarms.
3. Check application logs.
4. Check ALB target health where applicable.
5. Verify the container image and deployment status.

## Security

Container images are required to pass Cosign signature verification
before Terraform provisioning proceeds.
