# BUILD_NOTES — What We Built, In Order, and Why

This is a personal learning reference, not a changelog. The goal is to capture *why* decisions were made and *what was learned* at each step — the kind of context that git commit messages don't hold.

---

## Stage 1 — Project Structure & Documentation Scaffold
**Commit:** `62fddff` — 2026-03-11

### What was created
- `.gitignore` — Pre-configured to exclude Terraform state files (`.terraform/`, `*.tfstate`, `*.tfplan`), AWS credentials (`.aws/`), and macOS artifacts (`.DS_Store`). Keeps secrets and generated files out of git.
- `CLAUDE.md` — Instructions for Claude Code so it understands the project context in every session
- `README.md` — High-level overview of the project and doc map
- `docs/` — All documentation templates: `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `ATTACK_LOG.md`, `DETECTIONS.md`, `HARDENING.md`

### Why this came first
Setting up the documentation scaffold before writing any infrastructure code is intentional. The docs define *what you're building and why* — having that in place means every Terraform file you write has a clear purpose. It also means you can paste `PROJECT_CONTEXT.md` into a new Claude session and pick up exactly where you left off.

### What to know
- No Terraform files existed at this point — just docs and project structure
- The `.gitignore` is critical: Terraform state files contain sensitive resource IDs and should never be committed. Remote state in S3 handles this properly (see Stage 3).

---

## Stage 2 — First Terraform Files: Providers, Versions, Variables, Locals
**Commit:** `2e19c39` — 2026-03-13 (all TF files landed in one commit, built in stages)

### What was built and in what order

#### 1. `providers.tf` — AWS Provider
```hcl
provider "aws" {
  region = var.region
}
```
**What this does:** Tells Terraform which cloud provider to use and which region to deploy into. The region is driven by a variable (not hardcoded) so you can change it without touching provider config.

**Why it comes first:** Every other Terraform resource depends on the provider being declared. It's the foundation everything else references.

**Concept to know — Terraform providers:** Providers are plugins that Terraform downloads to know how to talk to a specific cloud or service (AWS, GCP, Datadog, etc.). The `provider "aws"` block configures the AWS provider. Without it, no `aws_*` resources work.

---

#### 2. `versions.tf` — Version Constraints
```hcl
terraform {
  required_version = ">= 1.12.2, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}
```
**What this does:** Locks the minimum Terraform CLI version and the AWS provider version. Anyone (or any CI pipeline) running this code gets the same behavior.

**Why it matters:** Terraform and provider versions introduce breaking changes. Pinning versions prevents "it works on my machine" situations. The `~>` operator (pessimistic constraint) means "5.100 or any 5.x patch, but not 6.0."

**Note:** CLAUDE.md currently says `>= 1.3.0` — the actual constraint in `versions.tf` is `>= 1.12.2`. This is because `use_lockfile` (native S3 state locking) requires Terraform 1.10+. CLAUDE.md should be updated to reflect this.

---

#### 3. `locals.tf` — Derived Values
```hcl
locals {
  name_prefix = "juice-shop-${var.environment}"
  tags = merge(var.tags, {
    Environment = var.environment
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
  })
}
```
**What this does:** Defines computed values used across multiple resources. `name_prefix` gives every resource a consistent name (e.g., `juice-shop-dev-vpc`). `tags` merges the base tags variable with standard tags applied to everything.

**Why locals instead of variables:** Locals are derived — computed from other values. Variables are inputs (things you pass in). You don't want someone to accidentally override `ManagedBy = "terraform"` or `Environment`; they should always be consistent.

**Why consistent tagging matters in AWS:** Tags are how you track cost per project/environment in AWS Cost Explorer. Without them, you can't tell which resources belong to which project on your bill.

---

#### 4. `variables.tf` — All Input Variables
Defines every configurable input with defaults:

| Variable | Default | Purpose |
|---|---|---|
| `region` | `us-east-1` | AWS deployment region |
| `environment` | `dev` | Used in resource names and tags |
| `owner_tag` | `juice-shop-team` | Cost attribution tag |
| `vpc_cidr` | `10.10.0.0/16` | VPC address space |
| `public_subnet_cidrs` | `["10.10.1.0/24", "10.10.2.0/24"]` | ALB subnets (2 AZs) |
| `private_subnet_cidrs` | `["10.10.11.0/24", "10.10.12.0/24"]` | ECS task subnets (2 AZs) |
| `container_image` | `bkimminich/juice-shop:latest` | Juice Shop Docker image |
| `container_port` | `3000` | Port Juice Shop listens on |
| `task_cpu` | `256` | ECS task CPU units (0.25 vCPU) |
| `task_memory` | `512` | ECS task memory (MiB) |
| `log_retention_days` | `30` | CloudWatch log retention |
| `alb_ingress_cidr` | `0.0.0.0/0` | Who can reach the ALB (lock down in Phase 5) |

**Why define all variables upfront:** Future Terraform files (ECS, ALB, IAM) will reference these same variables. Defining them here means you're not scattering variable declarations across files and hunting for them later.

**Note — region mismatch to resolve before `terraform init`:** `variables.tf` defaults `region` to `us-east-1` but the S3 state backend in `backend.tf` is in `us-east-2`. You should either:
- Change the `region` default in `variables.tf` to `us-east-2`, or
- Always pass `-var="region=us-east-2"` when running `terraform apply`

For a single-environment dev lab, changing the default to `us-east-2` is simpler.

---

#### 5. `vpc.tf` — The VPC and All Networking
The full network layer in one file. Resources created (in dependency order):

1. **`aws_vpc.main`** — The VPC itself. CIDR `10.10.0.0/16` gives 65,536 addresses — far more than needed, but standard practice for a /16 VPC. DNS support and DNS hostnames enabled (required for ECS service discovery and ALB to work correctly).

2. **`aws_subnet.public` (x2)** — Two public subnets, one per Availability Zone. The `count` meta-argument loops over the `public_subnet_cidrs` list so you get one subnet per CIDR. Public subnets have `map_public_ip_on_launch = true` — resources placed here get a public IP. The ALB goes here.

3. **`aws_subnet.private` (x2)** — Two private subnets, one per AZ. `map_public_ip_on_launch = false` — no public IPs. ECS Fargate tasks go here and reach the internet via the NAT Gateway.

4. **`aws_internet_gateway.main`** — Attached to the VPC. Allows traffic to flow between the public subnets and the internet. Without this, nothing in the public subnets can reach the internet and no inbound traffic can reach the ALB.

5. **`aws_route_table.public`** — Routes all outbound traffic (`0.0.0.0/0`) from public subnets to the Internet Gateway. Associated with both public subnets via `aws_route_table_association.public`.

6. **`aws_eip.nat`** — An Elastic IP (static public IP) for the NAT Gateway. NAT Gateways require a fixed IP so outbound traffic from private subnets appears to come from a consistent address.

7. **`aws_nat_gateway.main`** — Placed in the first public subnet. Private subnet resources (ECS tasks) route outbound traffic here; the NAT Gateway then forwards it to the internet. Inbound connections from the internet cannot initiate through a NAT Gateway — this is what keeps ECS tasks private.

8. **`aws_route_table.private`** — Routes all outbound traffic from private subnets to the NAT Gateway. Associated with both private subnets.

**Key concept — why public/private subnet split:**
- ALB in public subnets: needs to accept inbound traffic from the internet
- ECS tasks in private subnets: should never be directly reachable from the internet (even though Juice Shop is intentionally vulnerable, you still want traffic to flow *through* the ALB, not directly to containers)
- NAT Gateway: lets ECS tasks pull Docker images and make outbound calls, without exposing them inbound

**Cost note:** NAT Gateway has an hourly charge (~$0.045/hr) plus per-GB data processing. Using a single NAT Gateway (not one per AZ) saves ~50% cost. For a dev lab this is fine; in production you'd want one per AZ for availability.

---

## Stage 3 — Terraform Remote State Backend
**Part of commit:** `2e19c39` — 2026-03-13

### What was done manually in the AWS console
Before writing `backend.tf`, the S3 bucket for state storage was manually created:
- **Bucket name:** `tf-state-juice-shop-james-369042512949` (account ID suffix makes it globally unique)
- **Region:** `us-east-2`
- **Encryption:** Enabled (SSE-S3)
- **Versioning:** Should be enabled — allows you to recover previous state files if something goes wrong

A DynamoDB table was also created in the console during this session. However, it turned out not to be needed (see below).

### `backend.tf`
```hcl
terraform {
  backend "s3" {
    bucket       = "tf-state-juice-shop-james-369042512949"
    key          = "juice-shop/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

**What this does:** Tells Terraform to store its state file in S3 instead of locally. The `key` is the path within the bucket where the state file lives.

**Why remote state matters:** Terraform state is the file that tracks what resources exist in AWS and maps them to your `.tf` code. Without it, Terraform can't know what already exists. Storing it in S3 means:
- It's not on your laptop (safe if your machine dies)
- Multiple people/sessions can share it
- It can be versioned and recovered

**Why `use_lockfile = true` instead of DynamoDB:** Terraform 1.10 introduced native S3 state locking. When you run `terraform apply`, Terraform creates a `.lock` file in S3 to prevent two runs from modifying state simultaneously. Previously, this required a DynamoDB table (`dynamodb_table` parameter). With `use_lockfile`, the DynamoDB table is not needed.

**The DynamoDB table created in the console is unused.** It doesn't affect anything and can be deleted if you want to clean up.

---

## What Comes Next — Not Yet Done

### Immediate: `terraform init`
`terraform init` must be run before any `terraform plan` or `terraform apply`. It:
1. Downloads the AWS provider plugin (specified in `versions.tf`)
2. Connects Terraform to the S3 backend (`backend.tf`) and migrates any local state
3. Creates `.terraform.lock.hcl` (pin provider versions — commit this file)

```bash
cd terraform
terraform init
```

If prompted about migrating state, say yes.

### Then: First `terraform apply` — Deploy the VPC
```bash
terraform plan    # review what will be created
terraform apply   # deploy it
```

This will create: VPC, 2 public subnets, 2 private subnets, IGW, NAT Gateway (+ EIP), public and private route tables and associations. ~8-10 resources.

### After VPC: Remaining Phase 1 Terraform
Still to write and apply:
- `ecs.tf` — ECS cluster, task definition, service
- `alb.tf` — ALB, target group, listener, health checks
- `iam.tf` — Task execution role, task role
- `security_groups.tf` — ALB inbound, ECS inbound from ALB only, ECS egress
- `cloudwatch.tf` — Log group for container logs
