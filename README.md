# OWASP Juice Shop + AWS + Datadog Security Lab

## What this is
A hands-on lab to deploy a deliberately vulnerable app (OWASP Juice Shop) to AWS (ECS Fargate), instrument it with Datadog, perform controlled exploits, build detections, and harden the environment.

## How to use these docs
- `docs/PROJECT_CONTEXT.md` — Paste/upload to ChatGPT at the start of a session.
- `docs/ARCHITECTURE.md` — Track AWS design decisions.
- `docs/ATTACK_LOG.md` — Record exploits + telemetry evidence.
- `docs/DETECTIONS.md` — Track Datadog rules/monitors/dashboards.
- `docs/HARDENING.md` — Track security improvements + retest outcomes.

## Repo layout
- `terraform/` — IaC for AWS resources
- `docs/` — Project documentation
