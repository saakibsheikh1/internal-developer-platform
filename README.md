\# Internal Developer Platform



An Internal Developer Platform (IDP) built with Terraform and AWS to provide standardized, secure, and self-service infrastructure for application teams.



\## Project Overview



This project demonstrates how a platform team can provide reusable infrastructure templates, service catalogue capabilities, onboarding automation, governance controls, and platform metrics.



The platform is designed around standardized workload patterns instead of requiring developers to manually provision infrastructure.



\## Architecture



```text

&#x20;                        Internal Developer Platform

&#x20;                                     |

&#x20;            +------------------------+------------------------+

&#x20;            |                        |                        |

&#x20;            v                        v                        v

&#x20;      Web Service             Background Worker          Scheduled Job

&#x20;            |                        |                        |

&#x20;       ECS Fargate              ECS Fargate                 Lambda

&#x20;            |                        |                        |

&#x20;           ALB                       SQS                  EventBridge

&#x20;            |                        |                        |

&#x20;      CloudWatch                  DLQ                    ECS Task

&#x20;      SNS Alerts               Autoscaling                  DLQ

&#x20;            |                        |                        |

&#x20;          Email                  Monitoring                Logging

