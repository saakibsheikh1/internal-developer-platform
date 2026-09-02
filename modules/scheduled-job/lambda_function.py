import json
import os

import boto3

ecs = boto3.client("ecs")


def lambda_handler(event, context):
    cluster_arn = os.environ["ECS_CLUSTER_ARN"]
    task_definition_arn = os.environ["TASK_DEFINITION_ARN"]
    subnet_ids = os.environ["SUBNET_IDS"].split(",")
    security_group_id = os.environ["SECURITY_GROUP_ID"]

    response = ecs.run_task(
        cluster=cluster_arn,
        taskDefinition=task_definition_arn,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": subnet_ids,
                "securityGroups": [security_group_id],
                "assignPublicIp": "DISABLED",
            }
        },
    )

    execution_record = {
        "event": event,
        "task_definition": task_definition_arn,
        "tasks_started": len(response.get("tasks", [])),
        "failures": response.get("failures", []),
    }

    print(json.dumps(execution_record))

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Scheduled job launched",
                "tasks_started": len(response.get("tasks", [])),
            }
        ),
    }