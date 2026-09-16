"""Tiny demo service for aws-terraform-lab.

The same service as gcp-terraform-lab, so the comparison is about the
platform and not the app. APP_MESSAGE is injected from Secrets Manager
through the ECS task definition, which shows secret-backed configuration
end to end.
"""

import os

from fastapi import FastAPI

app = FastAPI(title="tf-lab-api")


@app.get("/")
def root() -> dict:
    return {
        "service": "tf-lab-api",
        "message": os.getenv("APP_MESSAGE", "APP_MESSAGE not set"),
    }


# The load balancer's target group health check calls this path. On Cloud
# Run it was renamed from /healthz because Google's frontend intercepts that
# path. The ALB has no such reserved path, but /health is kept so the app is
# identical on both clouds.
@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
