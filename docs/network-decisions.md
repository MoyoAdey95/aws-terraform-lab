# Network decisions

The network is a VPC with two public subnets in eu-west-2a and eu-west-2b, an internet gateway, and no private subnets. The ECS tasks run in the public subnets with public IPs. This page explains why, and what the more usual layout would cost.

## The usual layout, and why this lab does not use it

A typical AWS container setup puts the load balancer in public subnets and the tasks in private subnets. The tasks have no public IP, so they cannot be reached from the internet at all. They would still need to get out though. Fargate has to pull the image from ECR, read the secret from Secrets Manager and send logs to CloudWatch. From a private subnet there are two ways to do that.

The first is a NAT Gateway. It works, and it is what most Terraform modules create if you let them. It also bills by the hour whether or not anything passes through it, plus a charge for every gigabyte it processes. A standard NAT Gateway lives in one availability zone, so for resilience the usual pattern is one per zone. The price list also shows a regional NAT Gateway at the same hourly rate. I have not looked into how it is billed across zones, so the figures below use the per-zone pattern.

The second is VPC endpoints. Interface endpoints for ECR (two of them, `ecr.api` and `ecr.dkr`), CloudWatch Logs and Secrets Manager, plus a gateway endpoint for S3, where ECR keeps image layers. Gateway endpoints are free. Interface endpoints bill per endpoint, per availability zone, per hour, plus data processed.

## What each option costs

On-demand prices for eu-west-2, taken from the AWS Pricing API on 16 September 2026. A month is taken as 730 hours.

| Item | Price | Per month |
|---|---|---|
| NAT Gateway | $0.05 per hour, plus $0.05 per GB processed | $36.50 each, before data |
| Interface VPC endpoint | $0.011 per hour per AZ, plus $0.01 per GB | $8.03 per endpoint per AZ |
| Public IPv4 address | $0.005 per hour, in use or idle | $3.65 each |

For this lab across two availability zones that works out as follows.

Two NAT Gateways come to $73.00 a month before any data, plus $7.30 for their two public IPs.

Four interface endpoints in two zones is eight endpoint-hours every hour, which comes to $64.24 a month before data.

Public subnets with one running task cost $3.65 a month for the task's public IP.

The load balancer's own public IPs are charged in all three layouts, so they are left out of the comparison.

In a lab that is up for a few hours at a time, all of these are pennies. The difference only shows over a month, and that is the number a production bill is built from. I would rather make the decision on the monthly figure than on the fact that a single session is cheap.

## What the public subnet layout gives up

The tasks have public IPs, and that is the real trade. What keeps them unreachable is the tasks security group, which only accepts the app port from the load balancer's security group. Nothing else is allowed in, from the internet or from inside the VPC. That is a single control where the private subnet layout has two, the security group and the lack of a route in.

`map_public_ip_on_launch` is false on both subnets, so a public IP is only assigned where the ECS service asks for one. Nothing else placed in these subnets picks one up by default.

The default security group has had all its rules removed, so anything launched without an explicit group gets no access at all.

## What I would do in production

Private subnets for the tasks, no public IPs on them, and the load balancer as the only thing in the public subnets. Whether to use NAT Gateways or endpoints depends on what else the tasks talk to. Endpoints are cheaper once there are only a few AWS services involved and nothing needs the wider internet. NAT Gateways make more sense when the application calls third-party APIs, since endpoints only cover AWS services. Either way, the one thing I would not do is let a module create NAT Gateways without the decision being written down, because that is how they end up on a bill nobody expected.

## Checking it

After apply, `aws ec2 describe-nat-gateways` filtered to this VPC returned an empty list, and `describe-subnets` showed both subnets with `MapPublicIpOnLaunch` false. `describe-security-group-rules` showed the tasks group with exactly one inbound rule, port 8080 from the load balancer group, and the default group with no rules.
