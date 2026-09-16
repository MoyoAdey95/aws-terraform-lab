# aws-terraform-lab

A container platform on AWS, rebuilt from a stack I first ran on GCP in [gcp-terraform-lab](https://github.com/MoyoAdey95/gcp-terraform-lab). The application is deliberately trivial. The question the repo answers is whether the architecture transfers, and what differs on AWS as opposed to GCP.

Personal lab, not client or production work. Most of my previous cloud work is on GCP. This is a stack I have built on AWS end to end. Deployed, tested and torn down by me in eu-west-2. The 12 month free tier on this account has expired, so everything here was billable, and the working pattern was build, capture evidence, destroy.

## Design

A small FastAPI service runs on ECS Fargate (ARM64) behind an internet-facing application load balancer. Terraform builds everything from `envs/dev`, using modules that mirror the layout of the GCP repo so the two can be read side by side.

```
internet --HTTP 80--> ALB (2 public subnets, 2 AZs)
                       |
                       +--8080, from the ALB security group only--> Fargate task
                                                                   |
                         ECR image, CloudWatch logs, Secrets Manager <--+ (execution role)

GitHub Actions --OIDC--> deploy role --> push to ECR, new task definition, update service
CloudWatch alarm (no healthy targets) --> SNS --> email
```

There is no NAT Gateway. The tasks sit in public subnets and are reachable only through the load balancer. The reasoning and the costs are in [docs/network-decisions.md](docs/network-decisions.md). The two ECS roles and the CI role are covered in [docs/iam-decisions.md](docs/iam-decisions.md).

## What's in here

```
app/                 FastAPI service and Dockerfile (from the GCP repo)
modules/
  network/           VPC, subnets, internet gateway, security groups
  ecr/               image repository, immutable tags, scan on push
  iam/               task execution role and task role
  ecs/               cluster, log group, task definition, service
  alb/               load balancer, target group, listener
  monitoring/        no healthy targets alarm, SNS email
  ci/                GitHub OIDC provider and deploy role
envs/dev/            composition root, variables, outputs, backend
.github/workflows/   terraform checks on every push, deploy on app changes
docs/                bootstrap, decisions, comparison, production deltas, evidence
```

## Deploying it

Prerequisites. Terraform 1.11 or later, the AWS CLI with a profile called `personal`, Docker, and a budget alert on the account before anything is created.

The state bucket has to exist first. [docs/bootstrap.md](docs/bootstrap.md) has the CLI commands. Then, from `envs/dev`, with an email address for alarms set in the shell:

```bash
export TF_VAR_alert_email="you@example.com"
terraform init
terraform apply -target=module.ecr
```

The service needs an image before it can start, so push one before the full apply. The repository has immutable tags, so each build gets its own tag.

```bash
aws ecr get-login-password --region eu-west-2 --profile personal | docker login --username AWS --password-stdin <account>.dkr.ecr.eu-west-2.amazonaws.com
docker build -t <account>.dkr.ecr.eu-west-2.amazonaws.com/aws-lab-api:v2 app/
docker push <account>.dkr.ecr.eu-west-2.amazonaws.com/aws-lab-api:v2
terraform apply
curl "http://$(terraform output -raw alb_dns_name)/"
```

Confirm the SNS subscription email, or no alarms will arrive. After that, pushes to `main` that change `app/` build and deploy through GitHub Actions. The deploy role only trusts this repository, and [docs/evidence](docs/evidence/) shows why its trust policy names the repository by ID as well as by name.

## Findings

A few things did not go the way I expected, and each changed the code or the docs.

The first image scan found 6 critical and 12 high CVEs, all in Debian packages from the base image. Upgrading packages at build time brought that down to a single high finding in zlib with no fix available.

The first CI deploy was refused by AWS. The repository uses GitHub's immutable OIDC subject, which includes the owner and repository IDs, and the trust policy only had the names.

The no healthy targets alarm was tested by scaling the service to zero. It fired, but nine minutes later.

The IAM policy simulator denied the execution role permission to write logs. The first real task wrote its logs fine, so the policy was correct and the simulator result was misleading.

The captured output for all of these is in [docs/evidence](docs/evidence/). [docs/aws-vs-gcp.md](docs/aws-vs-gcp.md) compares the two builds, and [docs/production-deltas.md](docs/production-deltas.md) lists what I would change for real use.

## Teardown

```bash
terraform destroy
```

`force_delete` on the ECR repository and a zero-day recovery window on the secret mean destroy is not blocked by images or a pending secret deletion. The state bucket is not managed by Terraform and stays.
