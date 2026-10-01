"""Minimal Lambda handler packaged by Terraform for the API Gateway example."""

import json
import os


def lambda_handler(event, context):
    """Return a health response through API Gateway's Lambda proxy integration."""
    del context

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Terraform CI pipeline API is healthy",
                "environment": os.getenv("ENVIRONMENT", "unknown"),
                "request_path": event.get("path", "/"),
            }
        ),
    }