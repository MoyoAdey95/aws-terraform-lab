# Evidence

Everything in this folder was written by the AWS CLI or the GitHub CLI straight into a file, on 16 September 2026, while the stack was running. Each file starts with the UTC time it was captured and the exact command that produced it. Nothing was retyped. Times inside the output are a mix of UTC and UK time (+01:00), depending on the tool.

## What it shows

**The app runs behind the load balancer.** `app-response.txt` is the ALB returning the app's JSON, including the message injected from Secrets Manager, and a 200 from `/health`. `target-health.txt` shows the task registered and healthy.

**CI deployed it, not me.** `task-definition.txt` shows revision 3 running the image tagged with commit `87e5315`, registered by `assumed-role/aws-lab-github-deploy/GitHubActions`. That is the OIDC role, so the pipeline pushed and deployed without any stored AWS key. The same file shows the Graviton runtime platform and that the secret is referenced by ARN, with no value in the task definition. `ecs-service.txt` has the rollout from revision 2 to 3 in its events.

**The first deploy failed, and why.** `ci-deploy-attempt-1-failed.txt` is the pipeline being refused by AWS with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. `ci-oidc-subject.txt` is the cause. The repository uses GitHub's immutable subject format, so the token's `sub` claim carries the owner and repository IDs, and the trust policy expected the plain names. `ci-deploy-attempt-2.txt` is the same run passing after the trust policy was corrected.

**The tasks cannot be reached directly.** `security-group-test.txt` calls the running task's public IP on port 8080 and times out, then calls the same path through the load balancer and gets a response. The tasks security group only accepts traffic from the load balancer's group.

**No NAT Gateway.** `no-nat-and-subnets.txt` is an empty NAT Gateway list for the VPC and both subnets with automatic public IPs switched off. The reasoning and the costs are in `docs/network-decisions.md`.

**Patching the base image mattered.** `ecr-images-and-scans.txt` shows the first image, `v1`, with 6 critical, 12 high, 5 medium and 4 low findings, all in Debian packages from `python:3.12-slim`. `v2` added an `apt-get upgrade` and dropped to one high finding, in zlib, with no fix published yet. The CI build has the same single finding. Immutable tags are why all three can still be compared.

**The alarm fires, slowly.** `alarm-history.txt` is the test of the no healthy targets alarm. The service was scaled to zero at 16:23 (UK time), the alarm went to ALARM at 16:32, and back to OK at 16:41 after the service was restored. Nine minutes is much slower than two one-minute periods suggest, because the load balancer stops publishing the metric when the target group is empty and the alarm then depends on missing data. `container-logs.txt` is the app's own logs in CloudWatch, including the load balancer's health checks.

**Cost allocation tags.** `cost-allocation-tags.txt` records the four tag keys being activated for cost allocation. Activation is not retroactive, which is why it was done as soon as resources carried the tags.
