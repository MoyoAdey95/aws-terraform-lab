# Bootstrap: the Terraform state bucket

Terraform keeps its state in S3, and the bucket that holds it has to exist before `terraform init` can run. It sits outside Terraform for that reason. This page records how it was built and gives the CLI commands to build the same thing from scratch.

## What exists

The bucket is `moyo-aws-lab-tfstate` in eu-west-2. State for this environment lives at `aws-terraform-lab/dev/terraform.tfstate`.

I built it in the AWS console rather than the CLI. That is safe here because nothing in Terraform manages the bucket, so there is no drift to worry about. The console was used for this bootstrap and for checking settings, and nothing that Terraform will later own gets created there.

The settings below were read back from AWS after the build with `get-bucket-versioning`, `get-bucket-encryption`, `get-public-access-block`, `get-bucket-ownership-controls`, `get-bucket-location` and `get-bucket-tagging`.

| Setting | Value |
|---|---|
| Region | eu-west-2 |
| Versioning | Enabled |
| Default encryption | SSE-S3 (AES256), bucket key enabled |
| Blocked encryption types | SSE-C |
| Public access block | All four settings on |
| Object ownership | BucketOwnerEnforced, so ACLs are disabled |
| Tags | project=aws-terraform-lab, env=dev, owner=moyo, managed-by=console-bootstrap |

Versioning matters more than anything else on this list. If anything corrupts the state file, the previous version is still there to restore.

SSE-C appeared as a blocked encryption type without me choosing it. The console applied it on creation. It stops anyone writing objects encrypted with a key they supply themselves, which Terraform doesn't do.

## Why there is no DynamoDB lock table

Older guides pair the state bucket with a DynamoDB table for locking. That pattern existed because S3 had no way to write an object only if it did not already exist, so a separate store was needed to stop two runs holding the lock at once. S3 now supports conditional writes, and the S3 backend uses them to create a `.tflock` object next to the state file. This became generally available in Terraform 1.11, and the `dynamodb_table` setting is deprecated.

The backend in `envs/dev/versions.tf` sets `use_lockfile = true` and requires Terraform 1.11 or later. One resource to bootstrap instead of two.

## Building it with the CLI

These commands produce the same bucket. They assume an AWS CLI profile called `personal`. Bucket names are global, so change `BUCKET` to something unused.

```bash
export BUCKET=moyo-aws-lab-tfstate
export REGION=eu-west-2
export AWS_PROFILE=personal

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true,"BlockedEncryptionTypes":{"EncryptionType":["SSE-C"]}}]}'

aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-ownership-controls --bucket "$BUCKET" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'

aws s3api put-bucket-tagging --bucket "$BUCKET" \
  --tagging 'TagSet=[{Key=project,Value=aws-terraform-lab},{Key=env,Value=dev},{Key=owner,Value=moyo},{Key=managed-by,Value=cli-bootstrap}]'
```

New buckets already get the public access block and BucketOwnerEnforced by default. They are set explicitly anyway, so the commands still say what the bucket should look like if those defaults ever change.

A bucket built this way gets `managed-by=cli-bootstrap`. The tag records how the resource came to exist, and this one was not built by Terraform.

Once the bucket exists, `terraform init` from `envs/dev/` connects to it.
