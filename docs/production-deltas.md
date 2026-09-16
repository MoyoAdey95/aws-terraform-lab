# Production deltas

This is a lab, built to be deployed, tested and destroyed in a day. These are the places where I made a lab choice on purpose, and what I would do instead for something that stays up or that other people depend on.

## Traffic and network

**HTTP only.** There is no domain, so there is no certificate and no HTTPS listener. Production gets a domain in Route 53, a certificate from ACM, an HTTPS listener, and port 80 redirecting to 443.

**Tasks in public subnets.** The tasks have public IPs and are kept unreachable only by their security group. Production moves them to private subnets with no public IPs, and reaches AWS services through VPC endpoints or a NAT Gateway, depending on whether the app needs the wider internet. The costs are in `docs/network-decisions.md`.

**No WAF.** The load balancer is open to the internet with nothing in front of it. Production would put AWS WAF with managed rule sets on the ALB.

**One task.** `desired_count` is 1, so a single task failure is an outage until ECS replaces it. Production runs at least two tasks spread across both availability zones, with autoscaling on CPU or request count.

## Identity and secrets

**Administrator access for Terraform.** I run Terraform through an Identity Center session with the AdministratorAccess permission set. Production applies from CI with a role scoped to what the stack manages, and a plan shown on pull requests and applied after review. Here, plans and applies ran from my laptop.

**The secret value is in Terraform state.** Terraform writes the demo message, so the value sits in the state file. The bucket is private and encrypted, and the value is a demo string, which is why that was acceptable here. For a real secret, Terraform would create the secret and the value would be set outside it, or generated and rotated by Secrets Manager.

**`ecs:RegisterTaskDefinition` on `*`.** That action cannot be limited to one task definition family. The PassRole condition already stops the pipeline registering a task that runs as any role other than the two ECS roles. Production would also alert on task definitions registered by anything other than the pipeline, using CloudTrail.

## Images

**One accepted high finding.** The running image has one high severity CVE, in zlib from the Debian base image. I accepted it for the lab. Production rebuilds on a schedule so fixes land when Debian ships them, and considers a smaller base image with fewer packages in the first place.

**Scanning does not block deploys.** Basic scanning runs on push, but the pipeline does not wait for or act on the result. Production would fail the pipeline on new critical findings, and would likely use enhanced scanning through Amazon Inspector, which rescans images as new CVEs are published.

**Writable container filesystem.** The container runs as a non-root user, but its root filesystem is writable. Production sets `readonlyRootFilesystem` and gives the app a scratch volume if it needs one.

## Deploying

**Terraform ignores the service's task definition.** Once CI deploys, the service runs whatever revision the pipeline last registered, and Terraform no longer rolls it back. The cost is that a task definition change made in Terraform does not deploy on its own. Production would pick one owner for the task definition, either the pipeline registering it from a template in the repo or Terraform with the image tag passed in, rather than splitting it.

## Monitoring

**Slow outage detection.** The no healthy targets alarm fired nine minutes after the service went to zero, because the load balancer stops publishing `HealthyHostCount` when there are no targets and the alarm then relies on missing data. Production adds an outside check, a Route 53 health check or a CloudWatch Synthetics canary that notices a failed request within a minute or two.

**Short log retention, no Container Insights.** Logs are kept for one day and per-task metrics are off, both to keep a lab cheap. Production keeps logs for as long as incident review and any compliance need, and turns Container Insights on.

## State and cost

**The state bucket was built by hand.** It has versioning, encryption and public access blocked, but no replication and no access logging. Production creates it from a small bootstrap stack, adds access logs, and considers cross-region replication.

**Build, evidence, destroy.** Everything here was torn down the same day. Production stays up, which is where the hourly items in this repo, the load balancer, public IPs and Fargate tasks, stop being pennies and become worth watching with the cost allocation tags this repo activated.
