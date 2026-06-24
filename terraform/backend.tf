# ─── REMOTE STATE BACKEND (S3 + DYNAMODB LOCK) ───────────────────────────────
#
# Moves Terraform state off the local disk into an encrypted, versioned S3
# bucket with a DynamoDB lock table. This protects against state loss, enables
# concurrency locking, and keeps state (which can contain sensitive attributes)
# out of the public Git repo.
#
# IMPORTANT — bootstrap dependency:
# The state bucket and lock table referenced below are NOT managed by this
# Terraform config. They are created once, out-of-band, by the founder via the
# AWS CLI (see the apply-runbook). Managing the state backend inside the same
# config whose state it holds creates a chicken-and-egg bootstrap problem and
# risks a `terraform destroy` deleting its own state store. Keep them external.
#
# Migration (founder step, NOT run by the orchestrator):
#   terraform init -migrate-state
# This copies the existing local terraform.tfstate into the S3 backend.
#
# NOTE: with -backend=false (used by the PR `validate` CI check), this block is
# ignored and `terraform validate` still passes — no credentials required.

terraform {
  backend "s3" {
    bucket         = "ravjotduhra-cloud-resume-tfstate"
    key            = "cloud-resume-challenge/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "cloud-resume-tfstate-lock"
    encrypt        = true
  }
}