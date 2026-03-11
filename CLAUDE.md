# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A hands-on cloud security lab: deploy OWASP Juice Shop (intentionally vulnerable) to AWS ECS Fargate, instrument with Datadog, perform controlled exploits, build detections, and harden the environment. This is a learning/demo project — the app is *meant* to be vulnerable in early phases.

## Terraform

All infrastructure lives in `terraform/`. Requires Terraform >= 1.3.0 and AWS provider ~> 5.0.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

To override defaults (region defaults to `us-east-1`, `desired_count` defaults to `1`):

```bash
terraform apply -var="region=us-west-2" -var="environment=dev"
```

### What's built so far

- `vpc.tf` — VPC (10.10.0.0/16), 2 public subnets (ALB), 2 private subnets (ECS), IGW, single NAT Gateway, route tables
- `variables.tf` — All input variables with defaults (region, environment, owner_tag, VPC CIDRs, container_image, container_port)
- `providers.tf` — AWS provider config

Still to be built: ECS cluster/task/service, ALB, CloudWatch log groups, IAM roles, CloudTrail, Datadog integration.

## Phase-based workflow

Work progresses through five phases (tracked in `docs/ARCHITECTURE.md`):

1. **Deploy** — Juice Shop on ECS Fargate behind ALB, logs to CloudWatch
2. **Instrument** — Datadog: ECS metrics, APM, log ingestion, CSPM, Cloud Workload Security
3. **Exploit** — Run Juice Shop challenges (SQLi, XSS, auth bypass, etc.), document telemetry
4. **Detect** — Build Datadog SIEM rules, monitors, dashboards from observed telemetry
5. **Harden** — WAF, security groups, IAM least privilege, container hardening; retest attacks

## Target AWS architecture

```
Client → ALB (public subnets) → ECS Fargate tasks (private subnets)
                              ↘ CloudWatch Logs → Datadog
ECS metrics/events → Datadog Infrastructure
CloudTrail → Datadog (control plane detections)
```

Juice Shop container: `bkimminich/juice-shop:latest`, port 3000.

## Documentation files

- `docs/PROJECT_CONTEXT.md` — Full project context and phase specs
- `docs/ARCHITECTURE.md` — AWS resource checklist, Datadog integration decisions, open questions
- `docs/ATTACK_LOG.md` — Per-attack entries: steps, payloads, telemetry observed, detection gaps
- `docs/DETECTIONS.md` — Datadog SIEM rules, CWS rules, CloudTrail detections, dashboards
- `docs/HARDENING.md` — Security changes, rationale, tradeoff notes, retest results

When adding an exploit, document it in `docs/ATTACK_LOG.md`. When building a detection, document it in `docs/DETECTIONS.md`. When hardening, document it in `docs/HARDENING.md`.
