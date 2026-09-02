# Payment API

## Overview

payment-api is the web-service component of the Internal Developer Platform.

It is deployed as an AWS ECS Fargate service behind an Application Load Balancer and is owned by the payments team.

## Architecture

The request flow is:

Client
? Application Load Balancer
? ECS Fargate Service
? Payment API Container

Supporting infrastructure includes:

- Amazon VPC
- Public and private subnets
- NAT Gateway
- Amazon ECR
- Application Load Balancer
- Amazon ECS Fargate
- Amazon CloudWatch
- Amazon SNS

## Runtime Configuration

| Component | Configuration |
|---|---|
| ECS Service | payment-api-dev-service |
| ECS Cluster | payment-api-dev-cluster |
| Load Balancer | payment-api-dev-alb |
| Target Group | payment-api-dev-tg |
| Container Port | 8080 |
| CPU | 256 |
| Memory | 512 MiB |
| Desired Tasks | 2 |
| Environment | dev |

## Dependencies

- Amazon ECR � container image storage
- Amazon ECS Fargate � container execution
- Application Load Balancer � incoming traffic
- Amazon VPC � networking
- NAT Gateway � outbound connectivity
- Amazon CloudWatch � monitoring and alarms
- Amazon SNS � alert notifications
- Cosign � container image signature verification

## Monitoring

CloudWatch monitoring covers:

- ECS CPU utilization
- ECS memory utilization
- ALB unhealthy host count

Container Insights is enabled on the ECS cluster.

## Deployment

The service is provisioned using Terraform through the Internal Developer Platform.

The platform standardizes:

- Resource naming
- Team tags
- Environment tags
- ManagedBy=IDP tags
- Container image signature verification

The web-service template requires a Cosign-signed container image.

## On-Call

**Owning Team:** payments

**On-call contact:** Payments team on-call rotation.

For incidents, check:

1. ECS task health
2. ALB target health
3. CloudWatch alarms
4. Application logs
5. Recent deployments

## Runbook

Operational procedures should cover:

- ECS task failures
- ALB unhealthy targets
- Container deployment failures
- High CPU or memory utilization
- Application health-check failures

## Service Status

**Deployment status:** Active

**Environment:** Development

**Service type:** Web Service
