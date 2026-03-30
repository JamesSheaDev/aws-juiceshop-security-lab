# ARCHITECTURE — AWS + Datadog Design Notes

## Current Status
- **Phase:** Pre-Phase 1 (Terraform foundation in progress)
- **Last updated:** 2026-03-30
- **What's done:** Terraform foundation files written, S3 state backend manually provisioned in AWS console. No `terraform apply` has been run — no AWS resources deployed yet.
- **Next action:** Run `terraform init` (to wire Terraform to the S3 backend) then `terraform plan` / `terraform apply` to deploy the VPC.

---

## Terraform State Backend
- **S3 bucket:** `tf-state-juice-shop-james-369042512949` (manually created in AWS console, us-east-2)
- **State key:** `juice-shop/terraform.tfstate`
- **Region:** `us-east-2`
- **Locking:** Native S3 locking via `use_lockfile = true` (Terraform 1.10+) — no DynamoDB table needed
- **Encryption:** Enabled (SSE)

> Note: A DynamoDB table was created in the AWS console during setup but is not referenced in `backend.tf`. It is not used. The `use_lockfile` approach handles state locking natively via S3.

---

## High-Level Diagram (Target)

```
Client → ALB (public subnets) → ECS Fargate Service (private subnets)
                              ↘ CloudWatch Logs → Datadog Logs / SIEM
ECS Metrics/Events → Datadog Infrastructure
ALB Access Logs (S3) → Datadog (optional)
CloudTrail → Datadog (control plane detections)
(Optional) APM sidecar → Datadog APM
(Optional) CWS agent → Datadog Cloud Workload Security
```

---

## AWS Resources — Build Checklist

### Terraform Backend (Pre-Phase 1)
- [x] S3 state bucket created (manually, AWS console)
- [x] `backend.tf` written — S3 + native S3 locking
- [x] `versions.tf` written — Terraform >= 1.10, AWS provider ~> 5.0
- [x] `providers.tf` written — AWS provider, region variable-driven
- [x] `locals.tf` written — `name_prefix`, merged `tags`
- [x] `variables.tf` written — all input variables with defaults
- [ ] `terraform init` run against live S3 backend

### Networking (Phase 1 — defined in TF, not yet applied)
- [x] `vpc.tf` written — VPC (10.10.0.0/16), subnets, IGW, NAT, route tables
- [ ] VPC deployed (`terraform apply`)
- [ ] 2 public subnets (ALB) — 10.10.1.0/24, 10.10.2.0/24
- [ ] 2 private subnets (ECS tasks) — 10.10.11.0/24, 10.10.12.0/24
- [ ] Internet Gateway
- [ ] NAT Gateway (single, in first public subnet)
- [ ] Public + private route tables
- [ ] Security groups (ALB → ECS, ECS egress)

### Compute (Phase 1 — not started)
- [ ] ECS Cluster
- [ ] ECS Task Definition (Juice Shop — `bkimminich/juice-shop:latest`, port 3000)
- [ ] ECS Service (Fargate, desired_count = 1 for dev)
- [ ] Task CPU: 256 / Memory: 512 (defaults — adjust if needed)

### Load Balancing (Phase 1 — not started)
- [ ] ALB (public subnets)
- [ ] Target group (port 3000, HTTP)
- [ ] Listener (HTTP/80)
- [ ] Health checks

### Logging & Audit (Phase 1 — not started)
- [ ] CloudWatch log group for ECS container logs
- [ ] Log retention: 30 days (default)
- [ ] CloudTrail enabled (account-level)

### IAM (Phase 1 — not started)
- [ ] ECS task execution role (ECR + CloudWatch Logs)
- [ ] ECS task role (least privilege — no AWS API access initially)

---

## Datadog Integration Plan (Phase 2)

### Ingestion Strategy (decision pending)
- Options:
  - CloudWatch Logs forwarder Lambda → Datadog
  - AWS integration + log collection toggle in Datadog
- Leaning toward: CloudWatch forwarder (more control, standard pattern)

### Metrics
- ECS/Fargate container metrics via AWS integration
- ALB metrics via CloudWatch metrics integration

### APM
- Language: Node.js (Juice Shop is Express-based)
- Instrumentation: Datadog tracer sidecar or manual injection
- Service name: `juice-shop`

### Security Products
- Cloud SIEM — log-based detections (CloudWatch + CloudTrail)
- Cloud Workload Security (CWS) — runtime agent on ECS tasks
- CSPM — posture scanning for AWS account

---

## Open Questions
- WAF: Phase 5 (hardening). Use AWS WAF in front of ALB.
- TLS: Do we need HTTPS? ACM cert + ALB HTTPS listener. Deferred to Phase 5.
- RDS: Only if adding the optional custom Node app track.
- PrivateLink / VPC endpoints: Not planned unless egress costs become a concern.
- DynamoDB table in AWS console: Unused — delete or leave it. Does not affect anything.
