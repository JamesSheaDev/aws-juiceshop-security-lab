# ATTACK_LOG — Exploits, Evidence, and Telemetry

Use one section per attack or Juice Shop challenge.

---

## Attack Entry Template

### ID
- Attack/Challenge name:
- Date:
- Phase: 3 (Exploitation) or later

### Goal
What are you trying to demonstrate?

### Preconditions
- Environment state:
- Required accounts/roles:
- App URL:

### Steps / Payloads
Document exact steps taken.
- Step 1:
- Step 2:
- Requests / payloads:
  - (paste HTTP request, curl, payload string, etc.)

### Observed Behavior
- What happened in the app?
- What changed in data/session?

### Telemetry Produced
**Logs**
- Where (CloudWatch group / Datadog index)?
- Key log lines / fields:

**APM (if applicable)**
- Trace evidence:
- Service/resource:

**Runtime (if applicable)**
- Process/file/network events:

**CloudTrail (if applicable)**
- Related API calls:

### Detection Outcome
- What did Datadog catch automatically?
- What did it miss?
- What rules/monitors did you add?

### Notes / Improvements
- How to make it more realistic?
- How to reduce noise?
