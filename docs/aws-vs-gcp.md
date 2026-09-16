# AWS compared with GCP

This repo rebuilds the stack from gcp-terraform-lab on AWS. Same app, same shape of Terraform, same idea of a container behind a public endpoint with a secret injected and an alert when it goes down. What follows is what was different in practice, written after building both.

## Where AWS asked for more

**Networking.** On GCP the lab had a custom VPC and a subnet, and Cloud Run did not need the VPC to be reachable at all. Google's frontend took the traffic. On AWS nothing is reachable until I build the path to it. An internet gateway, a route table that points at it, subnets associated with that table, and at least two availability zones, because an application load balancer will not be created with fewer. That is five resources before anything can serve a request.

**The load balancer.** Cloud Run hands out an HTTPS URL. On AWS the equivalent is an ALB, a target group with a health check, and a listener. The ALB bills by the hour from the moment it exists, with or without traffic. The upside is that the health check path, thresholds and deregistration delay are all mine to set, and the default deregistration delay of five minutes would have slowed every deploy and every destroy in a lab.

**Firewalls.** GCP firewall rules live on the network and pick targets by tag or service account. AWS security groups are attached to each resource's network interface. The idea is close, but the AWS version lets one group reference another as the source, which is how the tasks accept traffic only from the load balancer. The test for that is in `docs/evidence/security-group-test.txt`. The task has a public IP and a direct call to it times out.

**Identity for the workload.** The GCP repo had one runtime service account. ECS uses two roles, one that ECS itself uses to pull the image, write logs and fetch the secret, and one that the app runs as. The app here calls no AWS APIs, so its role has no permissions. On top of that, every AWS role has a trust policy saying who may assume it, and for a service principal that policy should be limited to this account. GCP has the same concerns, but they are spread across IAM bindings on the service account rather than written into the role.

**Outbound access without a NAT.** The tasks need to reach ECR, CloudWatch Logs and Secrets Manager. In private subnets that means a NAT Gateway or a set of VPC endpoints, both billed by the hour. I put the tasks in public subnets instead and priced the alternatives in `docs/network-decisions.md`. None of this came up on Cloud Run.

## Where AWS asked for less

**APIs.** gcp-terraform-lab had to enable six Google APIs before it could create anything, and its README warns that this makes the first apply slower. AWS services are simply available in the account.

**Image scanning.** ECR scans on push with basic scanning at no extra charge, and that scan found 27 issues in the first image. See `docs/evidence/ecr-images-and-scans.txt`.

## Deploying from CI

The GCP repo's workflow validated the Terraform and never authenticated to GCP, so it held no credentials at all. Its docs say production would deploy from CI with Workload Identity Federation. This repo does that on AWS. GitHub Actions gets a short-lived token, AWS checks it against the deploy role's trust policy, and the job pushes and deploys with no stored key. `docs/evidence/task-definition.txt` shows the running revision registered by that role.

The first deploy was refused. The repository uses GitHub's immutable subject format, which puts the owner and repository IDs into the token's `sub` claim, and the trust policy expected plain names. I kept the IDs in the fix, because a name can be claimed by someone else after a rename and an ID cannot.

## Monitoring

The GCP repo's uptime check probed the service from outside. The alarm here watches the load balancer's `HealthyHostCount`. When the service was scaled to zero, the load balancer stopped publishing that metric altogether, and the alarm only fired once CloudWatch treated the missing data as breaching, nine minutes after the outage began. An outside probe does not have that gap, which is the main thing I would take back from this comparison into a production design.
