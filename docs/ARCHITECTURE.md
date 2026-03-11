# ARCHITECTURE — AWS + Datadog Design Notes

## Current Phase
- Phase: (1/2/3/4/5)
- Date last updated:
- Owner:

---

## High-Level Diagram (Text)
(Describe the flow; add an image later if you want.)

Client -> ALB (public) -> ECS Fargate Service (private subnets) -> (Optional) RDS / other deps
                    \-> CloudWatch Logs -> Datadog Logs / SIEM
ECS Metrics/Events -> Datadog Infrastructure
(Optional) APM -> Datadog APM
(Optional) Runtime -> Datadog Cloud Workload Security
CloudTrail -> Datadog (via ingestion/integration)

---

## AWS Resources (Checklist)
### Networking
- [ ] VPC
- [ ] Public subnets (ALB)
- [ ] Private subnets (ECS tasks)
- [ ] Route tables / NAT (if needed)
- [ ] Security groups

### Compute
- [ ] ECS Cluster
- [ ] ECS Task Definition (Juice Shop)
- [ ] ECS Service
- [ ] Autoscaling (optional)

### Load Balancing
- [ ] ALB
- [ ] Target group
- [ ] Listener (HTTP/HTTPS)
- [ ] Health checks

### Logging & Audit
- [ ] CloudWatch log group(s)
- [ ] CloudTrail enabled

### Secrets & IAM
- [ ] Task execution role
- [ ] Task role (least privilege)
- [ ] Secrets Manager (later)

---

## Datadog Integration Decisions
- Ingestion path for ECS logs:
  - ( ) CloudWatch forwarder
  - ( ) AWS integration + log collection
  - Notes:
- APM:
  - Language/instrumentation:
  - Service name conventions:
- Runtime Security:
  - Enabled? Y/N
  - Rules needed:

---

## Open Questions / Future Enhancements
- WAF? When?
- RDS? When?
- TLS / ACM cert?
- PrivateLink / VPC endpoints?
