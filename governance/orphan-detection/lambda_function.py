import json
import os

import boto3


ecs = boto3.client("ecs")
s3 = boto3.client("s3")
sns = boto3.client("sns")


CATALOGUE_BUCKET = os.environ["CATALOGUE_BUCKET"]
CATALOGUE_KEY = os.environ.get("CATALOGUE_KEY", "catalogue/services.json")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def load_catalogue_services():
    response = s3.get_object(
        Bucket=CATALOGUE_BUCKET,
        Key=CATALOGUE_KEY,
    )

    catalogue = json.loads(response["Body"].read())

    if isinstance(catalogue, dict):
        services = catalogue.get("services", [])
    else:
        services = catalogue

    registered_names = set()

    for service in services:
        if isinstance(service, str):
            registered_names.add(service)
        elif isinstance(service, dict):
            name = service.get("name")
            if name:
                registered_names.add(name)

    return registered_names


def get_ecs_services():
    deployed_services = []

    clusters_response = ecs.list_clusters()

    for cluster_arn in clusters_response.get("clusterArns", []):
        paginator = ecs.get_paginator("list_services")

        for page in paginator.paginate(cluster=cluster_arn):
            service_arns = page.get("serviceArns", [])

            if not service_arns:
                continue

            response = ecs.describe_services(
                cluster=cluster_arn,
                services=service_arns,
                include=["TAGS"],
            )

            for service in response.get("services", []):
                if service.get("status") != "ACTIVE":
                    continue

                tags = {
                    tag["key"]: tag["value"]
                    for tag in service.get("tags", [])
                }

                deployed_services.append(
                    {
                        "name": service["serviceName"],
                        "cluster": cluster_arn.split("/")[-1],
                        "team": tags.get("Team", "unknown"),
                        "environment": tags.get(
                            "Environment",
                            "unknown",
                        ),
                        "managed_by": tags.get(
                            "ManagedBy",
                            "unknown",
                        ),
                    }
                )

    return deployed_services


def lambda_handler(event, context):
    registered_services = load_catalogue_services()
    deployed_services = get_ecs_services()

    orphaned_services = []

    for service in deployed_services:
        service_name = service["name"]

        if service_name not in registered_services:
            service["status"] = "UNREGISTERED"
            orphaned_services.append(service)

    if orphaned_services:
        message = {
            "status": "UNREGISTERED",
            "count": len(orphaned_services),
            "services": orphaned_services,
        }

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="IDP Orphan Service Detected",
            Message=json.dumps(message, indent=2),
        )

        print(json.dumps(message, indent=2))

    else:
        message = {
            "status": "HEALTHY",
            "count": 0,
            "message": "All active ECS services are registered in the service catalogue.",
        }

        print(json.dumps(message, indent=2))

    return {
        "statusCode": 200,
        "body": json.dumps(message),
    }
