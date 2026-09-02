# Payment API

## Overview

`payment-api` is the web-service component of the Internal Developer Platform.

It is deployed as an AWS ECS Fargate service behind an Application Load Balancer and is owned by the `payments` team.

| Property | Value |
|---|---|
| Service | `payment-api` |
| Team | `payments` |
| Environment | `dev` |
| Service Type | Web Service |
| Deployment Status | Active |
| Platform | AWS |
| Compute | ECS Fargate |
| Container Port | `8080` |
| Desired Tasks | `2` |

---

## Architecture

The Payment API follows this request flow:

Client
  |
Application Load Balancer
  |
ECS Fargate Service
  |
Payment API Container
Supporting Infrastructure

The service uses the following infrastructure:

Amazon VPC
Public subnets
Private subnets
NAT Gateway
Amazon ECR
Application Load Balancer
Amazon ECS Fargate
Amazon CloudWatch
Amazon SNS
Runtime Configuration
Component	Configuration
ECS Service	payment-api-dev-service
ECS Cluster	payment-api-dev-cluster
Load Balancer	payment-api-dev-alb
Target Group	payment-api-dev-tg
Container Port	8080
CPU	256
Memory	512 MiB
Desired Tasks	2
Environment	dev
Dependencies

The Payment API depends on the following platform services:

Amazon ECR - container image storage
Amazon ECS Fargate - container execution
Application Load Balancer - incoming traffic
Amazon VPC - networking
NAT Gateway - outbound connectivity
Amazon CloudWatch - monitoring and alarms
Amazon SNS - alert notifications
Cosign - container image signature verification
Monitoring

CloudWatch monitoring covers:

ECS CPU utilization
ECS memory utilization
ALB unhealthy host count

Container Insights is enabled on the ECS cluster.

Operational Checks

For an incident, check the following:

ECS service task health
ALB target health
CloudWatch CPU utilization
CloudWatch memory utilization
ALB unhealthy host count
Application logs
Recent container image deployment
Deployment

The Payment API is provisioned using Terraform through the Internal Developer Platform.

The platform standardizes:

Resource naming
Team tags
Environment tags
ManagedBy=IDP tags
Standard ECS configuration
CloudWatch monitoring
Container image signature verification
Deployment Flow
Developer
    |
    v
Internal Developer Platform
    |
    v
Terraform
    |
    v
AWS Infrastructure
    |
    +--> VPC
    |
    +--> ECR
    |
    +--> ECS Fargate
    |
    +--> Application Load Balancer
    |
    +--> CloudWatch
    |
    +--> SNS
Container Image Security

The web-service template requires a Cosign-signed container image.

The deployment process verifies the container image signature before creating the ECS service.

Docker Image
     |
     v
Cosign Signature Verification
     |
     +---- Valid ----> Terraform deployment continues
     |
     +---- Invalid --> Deployment rejected

Unsigned container images are rejected by the platform's image signature verification guard.

On-Call

Owning Team: payments

On-call contact: Payments team on-call rotation.

Incident Response

When an incident occurs:

Check ECS service health.
Verify that ECS tasks are running.
Check ALB target health.
Review CloudWatch alarms.
Check application logs.
Review recent deployments.
Verify the container image if a new image was deployed.
Runbook

The Payment API operational runbook should cover:

ECS Task Failures

Check:

ECS task status
ECS task stopped reason
Container logs
Task definition configuration
ECR image availability
ALB Unhealthy Targets

Check:

ECS task status
Target group health
Container port 8080
Health-check configuration
Security group connectivity
High CPU Utilization

Check:

CloudWatch CPU metrics
Running ECS tasks
Recent deployments
Application workload
High Memory Utilization

Check:

CloudWatch memory metrics
ECS task memory configuration
Application logs
Recent deployments
Deployment Failure

Check:

Terraform output
ECS service events
Task definition
ECR image
Image signature verification
Image Signature Failure

Check:

Image reference
Cosign signature
Configured Cosign public key
ECR image availability
Service Health

The expected healthy state is:

Application Load Balancer
        |
        v
Target Group
        |
        +---- ECS Task 1 - Healthy
        |
        +---- ECS Task 2 - Healthy

The service is configured with 2 desired ECS tasks in the development environment.

Service Ownership
Property	Value
Service	payment-api
Owner Team	payments
Environment	dev
Lifecycle	production
Service Type	web-service
Platform	Internal Developer Platform
Infrastructure	Terraform
Runtime	ECS Fargate
Service Status

Deployment Status: Active

Environment: Development

Service Type: Web Service

Owner: Payments Team

Platform: Internal Developer Platform

Quick Reference
Item	Value
Service Name	payment-api
ECS Service	payment-api-dev-service
ECS Cluster	payment-api-dev-cluster
ALB	payment-api-dev-alb
Target Group	payment-api-dev-tg
Container Port	8080
CPU	256
Memory	512 MiB
Desired Count	2
Environment	dev
Owner	payments
Monitoring	CloudWatch
Alerting	SNS
Image Security	Cosign
Provisioning	Terraform