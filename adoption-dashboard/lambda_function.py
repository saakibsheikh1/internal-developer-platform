import json
import logging
import os
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone

import boto3


logger = logging.getLogger()
logger.setLevel(logging.INFO)

cloudwatch = boto3.client("cloudwatch")
s3 = boto3.client("s3")
ecs = boto3.client("ecs")
sns = boto3.client("sns")


NAMESPACE = os.environ.get("METRICS_NAMESPACE", "IDP/Platform")
CATALOGUE_BUCKET = os.environ.get("CATALOGUE_BUCKET", "")
ECS_CLUSTER = os.environ.get("ECS_CLUSTER", "")
PLATFORM_ALERT_TOPIC = os.environ.get("PLATFORM_ALERT_TOPIC", "")


def utc_now():
    return datetime.now(timezone.utc)


def parse_timestamp(value):
    if not value:
        return None

    try:
        return datetime.fromisoformat(
            str(value).replace("Z", "+00:00")
        )
    except (ValueError, TypeError):
        return None


def put_metric(metric_name, value, unit="Count", dimensions=None):
    metric = {
        "MetricName": metric_name,
        "Value": float(value),
        "Unit": unit,
    }

    if dimensions:
        metric["Dimensions"] = [
            {"Name": key, "Value": str(value)}
            for key, value in dimensions.items()
        ]

    cloudwatch.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=[metric],
    )


def publish_alert(subject, message):
    """
    Publish a platform alert directly to SNS.

    CloudWatch alarms also use the same SNS topic for aggregate
    threshold-based alerts.
    """

    if not PLATFORM_ALERT_TOPIC:
        logger.warning(
            "PLATFORM_ALERT_TOPIC is not configured; alert skipped: %s",
            subject,
        )
        return False

    try:
        sns.publish(
            TopicArn=PLATFORM_ALERT_TOPIC,
            Subject=subject[:100],
            Message=message,
        )

        logger.info("Platform alert published: %s", subject)
        return True

    except Exception:
        logger.exception(
            "Unable to publish platform alert: %s",
            subject,
        )
        return False


def load_catalogue():
    """
    Load catalogue data from the configured S3 bucket.

    Expected catalogue object:
      catalogue/services.json

    Supported service fields:
      name
      owner
      template_type
      template_version
      environment
      deployment_status
      onboarding_started_at
      deployment_completed_at
      golden_path_compliant
      runbook
      dashboard
    """

    if not CATALOGUE_BUCKET:
        logger.warning("CATALOGUE_BUCKET is not configured.")
        return []

    try:
        response = s3.get_object(
            Bucket=CATALOGUE_BUCKET,
            Key="catalogue/services.json",
        )

        body = response["Body"].read().decode("utf-8")
        data = json.loads(body)

        if isinstance(data, dict):
            services = data.get("services", [])
        elif isinstance(data, list):
            services = data
        else:
            services = []

        logger.info(
            "Loaded %s services from catalogue.",
            len(services),
        )

        return services

    except s3.exceptions.NoSuchKey:
        logger.warning(
            "Catalogue object does not exist yet."
        )
        return []

    except Exception:
        logger.exception(
            "Unable to load catalogue."
        )
        return []


def calculate_time_to_deploy(services):
    durations = defaultdict(list)

    for service in services:
        started = service.get("onboarding_started_at")
        completed = service.get("deployment_completed_at")
        template = service.get(
            "template_type",
            "unknown",
        )

        if not started or not completed:
            continue

        start_time = parse_timestamp(started)
        end_time = parse_timestamp(completed)

        if not start_time or not end_time:
            logger.warning(
                "Invalid onboarding timestamps for service %s.",
                service.get("name", "unknown"),
            )
            continue

        seconds = (
            end_time - start_time
        ).total_seconds()

        if seconds >= 0:
            durations[template].append(seconds)

    return durations


def percentile(values, percentile_value):
    if not values:
        return 0.0

    ordered = sorted(values)

    if len(ordered) == 1:
        return float(ordered[0])

    rank = (
        percentile_value / 100
    ) * (len(ordered) - 1)

    lower = int(rank)
    upper = min(
        lower + 1,
        len(ordered) - 1,
    )

    if lower == upper:
        return float(ordered[lower])

    fraction = rank - lower

    return (
        ordered[lower]
        + (
            ordered[upper]
            - ordered[lower]
        )
        * fraction
    )


def get_ecs_services():
    """
    Return active ECS service names and their Team tags.

    If ECS_CLUSTER is not configured, orphan detection is skipped.
    """

    if not ECS_CLUSTER:
        logger.warning(
            "ECS_CLUSTER is not configured."
        )
        return []

    services = []

    try:
        paginator = ecs.get_paginator(
            "list_services"
        )

        for page in paginator.paginate(
            cluster=ECS_CLUSTER
        ):
            services.extend(
                page.get(
                    "serviceArns",
                    [],
                )
            )

        if not services:
            return []

        result = []

        for start in range(
            0,
            len(services),
            10,
        ):
            batch = services[
                start:start + 10
            ]

            response = ecs.describe_services(
                cluster=ECS_CLUSTER,
                services=batch,
                include=["TAGS"],
            )

            for service in response.get(
                "services",
                [],
            ):
                tags = {
                    tag["key"]: tag["value"]
                    for tag in service.get(
                        "tags",
                        [],
                    )
                }

                result.append(
                    {
                        "name": service.get(
                            "serviceName"
                        ),
                        "team": tags.get(
                            "Team",
                            "unknown",
                        ),
                        "environment": tags.get(
                            "Environment",
                            "unknown",
                        ),
                    }
                )

        return result

    except Exception:
        logger.exception(
            "Unable to inspect ECS services."
        )
        return []


def calculate_metrics(
    services,
    ecs_services,
):
    total_services = len(services)

    template_counter = Counter(
        service.get(
            "template_type",
            "unknown",
        )
        for service in services
    )

    template_version_counter = Counter(
        service.get(
            "template_version",
            "unknown",
        )
        for service in services
    )

    team_counter = Counter(
        service.get(
            "owner",
            service.get(
                "team_name",
                "unknown",
            ),
        )
        for service in services
    )

    compliant_services = sum(
        1
        for service in services
        if (
            service.get(
                "golden_path_compliant"
            ) is True
            or str(
                service.get(
                    "golden_path_compliant",
                    "",
                )
            ).lower()
            == "true"
        )
    )

    compliance_rate = (
        (
            compliant_services
            / total_services
        )
        * 100
        if total_services
        else 100
    )

    registered_names = {
        service.get("name")
        for service in services
        if service.get("name")
    }

    unregistered = [
        item
        for item in ecs_services
        if (
            item.get("name")
            and item["name"]
            not in registered_names
        )
    ]

    catalogue_complete = 0

    for service in services:
        has_owner = bool(
            service.get("owner")
            or service.get("team_name")
        )

        has_runbook = bool(
            service.get("runbook")
            or service.get("runbook_link")
        )

        has_dashboard = bool(
            service.get("dashboard")
            or service.get("dashboard_link")
        )

        if (
            has_owner
            and has_runbook
            and has_dashboard
        ):
            catalogue_complete += 1

    catalogue_completeness = (
        (
            catalogue_complete
            / total_services
        )
        * 100
        if total_services
        else 100
    )

    durations = calculate_time_to_deploy(
        services
    )

    return {
        "total_services": total_services,
        "template_usage": dict(
            template_counter
        ),
        "template_versions": dict(
            template_version_counter
        ),
        "team_usage": dict(
            team_counter
        ),
        "golden_path_compliance": compliance_rate,
        "catalogue_completeness": (
            catalogue_completeness
        ),
        "unregistered_services": len(
            unregistered
        ),
        "unregistered_details": unregistered,
        "durations": durations,
    }


def build_deployment_daily_counts(services):
    """
    Calculate actual deployment completions by UTC calendar day.
    """

    today = utc_now().date()

    daily_counts = Counter()

    for service in services:
        completed = parse_timestamp(
            service.get(
                "deployment_completed_at"
            )
        )

        if not completed:
            continue

        deployment_date = (
            completed.date()
        )

        days_old = (
            today - deployment_date
        ).days

        if 0 <= days_old < 30:
            daily_counts[
                deployment_date.strftime(
                    "%Y-%m-%d"
                )
            ] += 1

    for offset in range(30):
        deployment_date = (
            today - timedelta(
                days=offset
            )
        )

        label = deployment_date.strftime(
            "%Y-%m-%d"
        )

        count = daily_counts.get(
            label,
            0,
        )

        put_metric(
            "DeploymentsPerDay",
            count,
            dimensions={
                "Date": label,
            },
        )

    return dict(daily_counts)


def build_weekly_onboarding_counts(
    services
):
    """
    Calculate services onboarded during each
    of the previous eight calendar weeks.

    Weeks start on Monday.
    """

    now = utc_now()
    current_week_start = (
        now
        - timedelta(
            days=now.weekday()
        )
    ).replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )

    weekly_counts = {}

    for offset in range(8):
        start = (
            current_week_start
            - timedelta(
                weeks=offset
            )
        )

        end = start + timedelta(
            weeks=1
        )

        count = 0

        for service in services:
            completed = parse_timestamp(
                service.get(
                    "deployment_completed_at"
                )
            )

            if not completed:
                continue

            if (
                start
                <= completed
                < end
            ):
                count += 1

        label = start.strftime(
            "%Y-%m-%d"
        )

        weekly_counts[label] = count

        put_metric(
            "ServicesOnboardedPerWeek",
            count,
            dimensions={
                "WeekStarting": label,
            },
        )

    return weekly_counts


def publish_unregistered_alerts(
    unregistered_services
):
    """
    Send a detailed SNS alert for every unregistered
    ECS service, including its Team tag.
    """

    for service in unregistered_services:
        service_name = service.get(
            "name",
            "unknown",
        )

        team = service.get(
            "team",
            "unknown",
        )

        environment = service.get(
            "environment",
            "unknown",
        )

        message = (
            "IDP unregistered service detected.\n\n"
            f"ECS service: {service_name}\n"
            f"Team tag: {team}\n"
            f"Environment tag: {environment}\n"
            f"ECS cluster: {ECS_CLUSTER}\n\n"
            "Action required: register the service "
            "in the IDP catalogue."
        )

        publish_alert(
            "IDP Unregistered ECS Service",
            message,
        )


def publish_metrics(metrics):
    put_metric(
        "ServicesOnboardedCumulative",
        metrics["total_services"],
    )

    put_metric(
        "GoldenPathComplianceRate",
        metrics["golden_path_compliance"],
        unit="Percent",
    )

    put_metric(
        "CatalogueCompletenessRate",
        metrics["catalogue_completeness"],
        unit="Percent",
    )

    put_metric(
        "UnregisteredServices",
        metrics["unregistered_services"],
    )

    for (
        template_type,
        count,
    ) in metrics[
        "template_usage"
    ].items():
        put_metric(
            "TemplateUsage",
            count,
            dimensions={
                "TemplateType": template_type,
            },
        )

    for (
        template_version,
        count,
    ) in metrics[
        "template_versions"
    ].items():
        put_metric(
            "TemplateVersionDistribution",
            count,
            dimensions={
                "TemplateVersion":
                    template_version,
            },
        )

    all_durations = []

    for (
        template_type,
        values,
    ) in metrics[
        "durations"
    ].items():
        if not values:
            continue

        all_durations.extend(values)

        average_seconds = (
            sum(values)
            / len(values)
        )

        put_metric(
            "AverageTimeToDeploy",
            average_seconds,
            unit="Seconds",
            dimensions={
                "TemplateType":
                    template_type,
            },
        )

        put_metric(
            "TimeToDeployP50",
            percentile(
                values,
                50,
            ),
            unit="Seconds",
            dimensions={
                "TemplateType":
                    template_type,
            },
        )

        put_metric(
            "TimeToDeployP99",
            percentile(
                values,
                99,
            ),
            unit="Seconds",
            dimensions={
                "TemplateType":
                    template_type,
            },
        )

    return True


def lambda_handler(
    event,
    context,
):
    logger.info(
        "Starting daily IDP platform metrics calculation."
    )

    services = load_catalogue()

    ecs_services = get_ecs_services()

    metrics = calculate_metrics(
        services,
        ecs_services,
    )

    publish_metrics(
        metrics
    )

    weekly_counts = (
        build_weekly_onboarding_counts(
            services
        )
    )

    daily_deployments = (
        build_deployment_daily_counts(
            services
        )
    )

    if metrics[
        "unregistered_services"
    ] > 0:
        publish_unregistered_alerts(
            metrics[
                "unregistered_details"
            ]
        )

    result = {
        "timestamp":
            utc_now().isoformat(),

        "namespace":
            NAMESPACE,

        "services_onboarded":
            metrics[
                "total_services"
            ],

        "template_usage":
            metrics[
                "template_usage"
            ],

        "template_version_distribution":
            metrics[
                "template_versions"
            ],

        "team_usage":
            metrics[
                "team_usage"
            ],

        "golden_path_compliance_percent":
            round(
                metrics[
                    "golden_path_compliance"
                ],
                2,
            ),

        "catalogue_completeness_percent":
            round(
                metrics[
                    "catalogue_completeness"
                ],
                2,
            ),

        "unregistered_services":
            metrics[
                "unregistered_services"
            ],

        "unregistered_details":
            metrics[
                "unregistered_details"
            ],

        "weekly_onboarding":
            weekly_counts,

        "daily_deployments":
            daily_deployments,

        "time_to_deploy": {
            template: {
                "count":
                    len(values),

                "average_seconds":
                    round(
                        sum(values)
                        / len(values),
                        2,
                    ),

                "p50_seconds":
                    round(
                        percentile(
                            values,
                            50,
                        ),
                        2,
                    ),

                "p99_seconds":
                    round(
                        percentile(
                            values,
                            99,
                        ),
                        2,
                    ),
            }

            for (
                template,
                values
            ) in metrics[
                "durations"
            ].items()

            if values
        },
    }

    logger.info(
        "IDP platform metrics result: %s",
        json.dumps(
            result,
            default=str,
        ),
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            result
        ),
    }