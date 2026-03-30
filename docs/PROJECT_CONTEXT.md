# PROJECT_CONTEXT — OWASP Juice Shop + AWS + Datadog Cloud Security Lab

## Purpose
This file is the **canonical, persistent context** for the project. Load it at the start of any session to give Claude (or any assistant) the baseline context needed to continue work without re-explaining the setup.

---

## Current Status (as of 2026-03-30)

**Active phase:** Pre-Phase 1 — Terraform foundation

| Area | Status |
|---|---|
| Terraform backend (S3 state bucket) | Provisioned manually in AWS console |
| `backend.tf`, `versions.tf`, `providers.tf`, `locals.tf`, `variables.tf` | Written |
| `vpc.tf` (VPC, subnets, IGW, NAT, routes) | Written — not yet applied |
| `terraform init` against live backend | Not run |
| Any AWS resources deployed | None |
| Datadog integration | Not started |

**Immediate next steps:**
1. Run `terraform init` to connect to the S3 backend
2. Run `terraform plan` / `terraform apply` to deploy the VPC
3. Write and apply remaining Phase 1 Terraform: ECS, ALB, IAM, CloudWatch

---

## Project Objective
Deploy OWASP Juice Shop to AWS using containerized infrastructure, instrument it deeply with Datadog, intentionally exploit known vulnerabilities, detect malicious activity using logs and runtime monitoring, and harden the environment — demonstrating secure cloud-native application practices end to end.

---

## AWS Architecture

**Region:** us-east-2 (matches state backend)

```
Client → ALB (public subnets) → ECS Fargate Service (private subnets)
                              ↘ CloudWatch Logs → Datadog Logs / SIEM
ECS Metrics/Events → Datadog Infrastructure
CloudTrail → Datadog (control plane detections)
```

**Core components:**
- ECS Fargate running `bkimminich/juice-shop:latest` (port 3000)
- ALB in public subnets; ECS tasks in private subnets
- VPC: 10.10.0.0/16 — 2 public (10.10.1/2.0/24), 2 private (10.10.11/12.0/24)
- Single NAT Gateway (cost-optimized for dev)
- CloudWatch Logs for container output
- CloudTrail for control plane auditing

**Later phases add:** Datadog APM sidecar, CWS agent, AWS WAF, Secrets Manager, GuardDuty

**Infrastructure as Code:** Terraform >= 1.10 (AWS provider ~> 5.0)

---

## Phase-Based Execution Model

### Phase 1 — Deploy the Vulnerable App
- Deploy OWASP Juice Shop "as-is" (intentionally vulnerable)
- Expose publicly through ALB
- Confirm ECS health checks + ALB routing
- Confirm logs flow to CloudWatch

**Exit criteria:**
- App reachable via ALB DNS
- ECS service stable (desired = running)
- Baseline CloudWatch logs present

---

### Phase 2 — Instrument with Datadog
**Infrastructure metrics:**
- ECS/Fargate integration
- ALB metrics via CloudWatch integration

**Application:**
- Datadog APM for Node.js (Juice Shop is Express-based)
- Distributed tracing + service overview

**Logs:**
- Container logs: CloudWatch → Datadog (forwarder Lambda)
- Optional: ALB access logs (S3) + ingestion strategy

**Security products:**
- Cloud Workload Security (runtime agent)
- Cloud SIEM (log-based detections)
- CSPM (posture scan of AWS account)

**Exit criteria:**
- Metrics visible in Datadog
- Logs searchable in Datadog
- Security products receiving data

---

### Phase 3 — Exploitation & Attack Simulation
Intentionally exploit Juice Shop vulnerabilities:
- SQL Injection
- XSS
- Authentication bypass / Broken access control
- Sensitive data exposure
- Other Juice Shop challenges as applicable

For each exploit, document in `docs/ATTACK_LOG.md`:
- Vulnerability exploited
- Steps + payloads
- Telemetry generated (logs / traces / runtime events)
- What Datadog detected vs. missed

---

### Phase 4 — Detection Engineering (Datadog)
Build detection content:
- Log-based SIEM rules (queries → monitors)
- Runtime detections (process / file / network via CWS)
- CloudTrail detections (IAM / API anomalies)
- Dashboards for "attack story" walkthrough
- Actionable, low-noise alerts

Document everything in `docs/DETECTIONS.md`.

---

### Phase 5 — Hardening & Remediation
**App layer:** Input validation, security headers, rate limiting
**Container layer:** Non-root user, minimal image, drop capabilities, read-only FS
**AWS layer:** Tight security groups, IAM least privilege, Secrets Manager, AWS WAF, GuardDuty

After each hardening change:
- Re-test attacks from Phase 3
- Confirm detections still trigger
- Confirm exploitability decreases

Document in `docs/HARDENING.md`.

---

## Optional Expansion — Custom Node App
If adding a secure service alongside Juice Shop:
- Simple Node/Express API → ECS → RDS Postgres
- Full Datadog APM + Logs + CSPM instrumentation
- Demonstrates contrast between vulnerable (Juice Shop) and secured (custom app) services

---

## Documentation Map
| File | Purpose |
|---|---|
| `docs/PROJECT_CONTEXT.md` | This file — canonical project context |
| `docs/ARCHITECTURE.md` | AWS resource checklist, build status, Datadog integration decisions |
| `docs/ATTACK_LOG.md` | Per-exploit entries: steps, payloads, telemetry, detection gaps |
| `docs/DETECTIONS.md` | Datadog SIEM rules, CWS rules, CloudTrail detections, dashboards |
| `docs/HARDENING.md` | Security changes, rationale, tradeoffs, retest results |
