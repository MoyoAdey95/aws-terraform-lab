# IAM decisions

Everything in this lab runs with one of three identities. I run Terraform as myself through IAM Identity Center, ECS uses the task execution role to start the container, and the app itself runs as the task role. No long-lived access keys exist anywhere in the account.

## How I authenticate

The AWS CLI profile is `personal`, backed by an Identity Center session that lasts 12 hours. There is no access key on disk. The cost of that showed up on day two, when the first `terraform init` failed with `InvalidGrantException` because the session had expired. `aws sso login --profile personal` fixed it.

The permission set is AdministratorAccess. That is a lab choice, and it is the first thing I would change for anything shared. See `docs/production-deltas.md`.

## Two roles for one container

On Cloud Run in gcp-terraform-lab, one runtime service account did everything. ECS splits that job in two.

The **task execution role** (`aws-lab-task-execution`) is used by ECS before and around the container, never by the app. It pulls the image from ECR, writes the container's logs to CloudWatch, and reads the secret that becomes `APP_MESSAGE`. The **task role** (`aws-lab-task`) is what code inside the container would use to call AWS. This app calls nothing, so the task role has no permissions at all.

The split matters if the app is compromised. Whoever controls the container gets the task role, which here can do nothing, and not the role that can pull images and read secrets.

The secret permission sits on the execution role for the same reason. ECS resolves the secret when the task starts and passes the value in as an environment variable, so the app never calls Secrets Manager itself.

## Scoping the execution role

AWS publishes a managed policy for this role, `AmazonECSTaskExecutionRolePolicy`. It allows pulling from every ECR repository in the account and writing to every log group. I wrote the policy out instead, so it covers one repository, one log group and one secret. The only action on `*` is `ecr:GetAuthorizationToken`, which has no resource to scope to.

Both roles trust `ecs-tasks.amazonaws.com` with two conditions, `aws:SourceAccount` set to this account and `aws:SourceArn` limited to ECS in this account and region. Without them, the trust policy trusts the ECS service as a whole rather than ECS acting for this account.

## Testing it

I checked the policies with the IAM policy simulator before anything ran. The execution role was allowed to pull from `aws-lab-api` and denied on a made-up repository, and the task role was denied ECR, CloudWatch Logs and Secrets Manager.

The simulator also denied `logs:PutLogEvents` for the execution role against a full log stream ARN, while allowing it against the log group pattern the policy uses. I left the policy as it was and tested it for real instead. The first task wrote its startup lines to CloudWatch, so the policy was right and the simulator result was not a reliable guide for that case. The simulator is a useful first check, but a real request is the one that counts.
