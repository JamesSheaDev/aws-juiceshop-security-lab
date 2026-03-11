# PROJECT_CONTEXT — OWASP Juice Shop + AWS + Datadog Cloud Security Lab

## Purpose
This file is the **canonical, persistent context** for the project.  
Paste it into ChatGPT at the start of a session (or upload this file) so the assistant always has the same baseline context.

---

## Project Objective
Deploy OWASP Juice Shop to AWS using containerized infrastructure, instrument it deeply with Datadog, intentionally exploit known vulnerabilities, detect malicious activity using logs and runtime monitoring, and harden the environment to demonstrate secure cloud-native application practices.

---

## Preferred AWS Architecture (Keep It Practical)
Default to a simple, realistic design:

- **AWS ECS (Fargate preferred)** running OWASP Juice Shop container
- **Application Load Balancer (ALB)** in front of ECS service
- **VPC**
  - Public subnets: ALB
  - Private subnets: ECS tasks
- **IAM roles** for ECS task execution / task role
- **CloudWatch Logs** enabled for containers
- **AWS CloudTrail** enabled (org/account-level if available)

Optional expansions (later phases):
- RDS Postgres (only if adding a custom app/service)
- AWS WAF (hardening phase)
- AWS Secrets Manager (hardening phase)
- GuardDuty (hardening phase)

**Infrastructure as Code:** Terraform preferred (but not required).

---

## Phase-Based Execution Model

### Phase 1 — Deploy the Vulnerable App
- Deploy OWASP Juice Shop “as-is” (intentionally vulnerable).
- Expose publicly through ALB.
- Confirm ECS health checks + ALB routing.
- Confirm logs flow to CloudWatch.

**Exit criteria**
- App reachable via ALB DNS
- ECS service stable
- Baseline logs present

---

### Phase 2 — Instrument with Datadog
Enable deep observability:

**Infrastructure**
- ECS integration
- Container metrics (ECS/Fargate)
- ALB metrics (if available via CloudWatch)

**Application**
- Datadog APM for Node (where applicable)
- Distributed tracing + service overview

**Logs**
- Ingest container logs from CloudWatch
- Optional: ALB access logs (S3) + ingestion strategy

**Security**
- Cloud Workload Security (runtime)
- Cloud SIEM (log detection)
- CSPM (posture) for AWS account

**Exit criteria**
- Metrics visible, traces flowing (if instrumented), logs searchable
- Security products enabled (as available) and receiving data

---

### Phase 3 — Exploitation & Attack Simulation
Intentionally exploit OWASP Juice Shop vulnerabilities, e.g.:
- SQL Injection
- XSS
- Authentication bypass / Broken access control
- Sensitive data exposure
- Other Juice Shop challenges as applicable

For each exploit, document:
- What was exploited (challenge/vuln)
- Steps performed (requests / payloads)
- What telemetry was generated (logs/traces/runtime events)
- What Datadog detected vs. missed (gaps)

---

### Phase 4 — Detection Engineering (Datadog)
Build detection content:
- Log-based detections (queries → monitors / SIEM rules)
- Runtime detections (process/file/network)
- CloudTrail detections (suspicious IAM/API activity)
- Dashboards for “attack story” walkthrough
- Alerts that are actionable (low noise)

Think like:
- Attacker
- SOC analyst
- Detection engineer

---

### Phase 5 — Hardening & Remediation
Incrementally secure the stack:

**App layer**
- Input validation
- Security headers (CSP, HSTS)
- Rate limiting
- Auth controls (JWT) if custom services are added

**Container layer**
- Non-root user
- Minimal base images
- Drop Linux capabilities
- Read-only filesystem (where feasible)

**AWS layer**
- Private subnets for tasks
- Tight Security Groups + NACLs if needed
- IAM least privilege
- Secrets Manager for secrets
- AWS WAF in front of ALB
- GuardDuty + CloudTrail monitoring

After each change:
- Re-test attacks
- Confirm detections still trigger
- Confirm exploitability decreases

---

## Optional Expansion Track — “Secure Simple Node App”
If adding a custom service alongside Juice Shop:

Build:
- Simple Node/Express API
- Dockerize
- Deploy to ECS
- RDS Postgres

Secure:
- JWT auth
- Rate limiting
- Input validation
- CSP headers
- Secrets Manager
- IAM roles (no hardcoded creds)
- VPC + private subnets
- Security groups
- CloudTrail

Instrument:
- Datadog APM
- Datadog Logs
- CSPM
- Cloud SIEM

Deliverable:
- Writeup: what was vulnerable, what was hardened, what Datadog detected

---

## How ChatGPT Should Help
Be implementation-focused and specific:
- Terraform examples when helpful
- AWS configuration guidance
- Datadog monitor queries and dashboards
- Explain telemetry behavior and gaps
- Explain tradeoffs (security / cost / complexity / demo value)

If context is unclear, ask:
- What phase are we in?
- What’s already implemented?
- Terraform or manual?
