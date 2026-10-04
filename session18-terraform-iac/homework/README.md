# Session 18 — Terraform & Infrastructure as Code (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | [Terraform S3 demo](terraform-s3-demo/) — init, fmt, validate, plan, apply, show, output, destroy | ✅ |
| 2.1 | [IAM](aws-services/01-iam/README.md) | ✅ |
| 2.2 | [EC2](aws-services/02-ec2/README.md) | ✅ |
| 2.3 | [S3](aws-services/03-s3/README.md) | ✅ |
| 2.4 | [VPC](aws-services/04-vpc/README.md) | ✅ |
| 2.5 | [DynamoDB & RDS](aws-services/05-dynamodb-rds/README.md) | ✅ |

## Task 1 — Terraform S3 Bucket

Bucket `chhavi-24bcs10201-<random-hex>` in `us-east-2` with versioning, AES-256 encryption and public access blocked. Details in [terraform-s3-demo/README.md](terraform-s3-demo/README.md).

```bash
cd session18-terraform-iac/homework/terraform-s3-demo
```

### 1. Init
```bash
terraform init
```
![terraform init downloads aws and random providers](../screenshots/tf-init.png)

### 2. Fmt & Validate
```bash
terraform fmt && terraform validate
```
![Configuration is valid](../screenshots/tf-fmt-validate.png)

### 3. Plan
```bash
terraform plan
```
![Plan: 5 to add, 0 to change, 0 to destroy](../screenshots/tf-plan.png)

### 4. Apply
```bash
terraform apply
```
![Apply complete with outputs](../screenshots/tf-apply.png)

### 5. Show & Output
```bash
terraform show
terraform output
```
![terraform show state of the bucket](../screenshots/tf-show.png)
![terraform output values](../screenshots/tf-output.png)

### 6. Verify in AWS
```bash
aws s3 ls | grep chhavi
```
![Bucket listed by AWS CLI / visible in S3 console](../screenshots/s3-console.png)

### 7. Destroy
```bash
terraform destroy
```
![Destroy complete: 5 destroyed](../screenshots/tf-destroy.png)

## Task 2 — AWS Services Research

| Service | Notes |
|---|---|
| IAM | [01-iam](aws-services/01-iam/README.md) |
| EC2 | [02-ec2](aws-services/02-ec2/README.md) |
| S3 | [03-s3](aws-services/03-s3/README.md) |
| VPC | [04-vpc](aws-services/04-vpc/README.md) |
| DynamoDB & RDS | [05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md) |
