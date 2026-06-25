# ─── GITHUB ACTIONS OIDC (CI AUTH — REPLACES STANDING STATIC KEYS) ───────────
#
# Goal: let the GitHub Actions deploy workflow assume a least-privilege AWS role
# via short-lived OIDC tokens, so no long-lived access keys live in GitHub
# secrets. The role can do EXACTLY what .github/workflows/deploy.yml needs and
# nothing else: PutObject on the single index.html object, and CreateInvalidation
# on the single CloudFront distribution.
#
# Trust is scoped to: this repo, the main branch ref only.

locals {
  github_repo = "RavjotD/cloud-resume-challenge-aws"

  # Allowed OIDC subjects. Production deploy is pinned to the main branch ref
  # ONLY. When var.enable_oidc_smoke_test is true, a single extra subject is
  # added for a dedicated, short-lived smoke-test branch so the OIDC assume path
  # can be validated (via a workflow_dispatch smoke-test workflow) BEFORE the
  # first real merge to main. This is a tightly-scoped exact-match ref, never a
  # wildcard, and must be set back to false once OIDC is confirmed working.
  oidc_allowed_subs = concat(
    ["repo:${local.github_repo}:ref:refs/heads/main"],
    var.enable_oidc_smoke_test ? ["repo:${local.github_repo}:ref:refs/heads/oidc-smoke-test"] : []
  )
}

# Account id for building the CloudFront distribution ARN below.
data "aws_caller_identity" "current" {}

# The CloudFront distribution the CI actually invalidates = the live site
# (d19mfjmr0dtnqm.cloudfront.net, id E509QCC92CXK5), which is the value of the
# CLOUDFRONT_DISTRIBUTION_ID GitHub secret. IMPORTANT: this is NOT the distribution
# Terraform currently manages (aws_cloudfront_distribution.resume = E1GD177QZ8CDPX /
# d1a154uj7j7dna, a stale duplicate from the original build). That drift is tracked
# for reconciliation; until then the deploy role must grant invalidation on the LIVE
# distribution so CI succeeds.
variable "deploy_cloudfront_distribution_id" {
  description = "ID of the live CloudFront distribution the CI invalidates (matches the CLOUDFRONT_DISTRIBUTION_ID secret)."
  type        = string
  default     = "E509QCC92CXK5"
}

# ─── OIDC PROVIDER ───────────────────────────────────────────────────────────
#
# The thumbprint is sourced dynamically from GitHub's OIDC TLS certificate chain
# rather than hardcoded. Since 2023 AWS STS verifies the GitHub OIDC token
# against IAM's trusted root CAs and the thumbprint is no longer used for the
# trust decision for token.actions.githubusercontent.com, but the IAM API still
# requires the field to be present. Computing it from the live cert avoids
# shipping a stale constant that breaks if GitHub rotates its CA.
#
# AWS validates against the thumbprint of the ROOT CA (the top-most cert in the
# chain), not the leaf, so we take the LAST certificate the data source returns
# rather than certificates[0] (the leaf).

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    data.tls_certificate.github_actions.certificates[length(data.tls_certificate.github_actions.certificates) - 1].sha1_fingerprint
  ]

  tags = {
    Project   = "cloud-resume-challenge"
    ManagedBy = "terraform"
    Purpose   = "github-actions-ci-oidc"
  }
}

# ─── DEPLOY ROLE (TRUST POLICY) ──────────────────────────────────────────────
#
# Federated trust: only tokens issued by the GitHub OIDC provider, with
# audience sts.amazonaws.com, and a subject pinned to this repo's main branch
# ref, may assume this role.

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_allowed_subs
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name                 = "github-actions-deploy"
  description          = "Least-privilege role assumed by GitHub Actions (OIDC) to deploy the cloud resume site."
  assume_role_policy   = data.aws_iam_policy_document.github_actions_trust.json
  max_session_duration = 3600

  tags = {
    Project   = "cloud-resume-challenge"
    ManagedBy = "terraform"
    Purpose   = "github-actions-ci-deploy"
  }
}

# ─── DEPLOY ROLE (LEAST-PRIVILEGE INLINE POLICY) ─────────────────────────────
#
# Exactly the two API calls deploy.yml makes:
#   1. aws s3 cp website/index.html s3://<bucket>/index.html   -> s3:PutObject
#   2. aws cloudfront create-invalidation --distribution-id ... -> cloudfront:CreateInvalidation
#
# Scoped to the single object ARN and the single distribution ARN. No wildcards
# beyond the resource specificity required by each API.

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid       = "PutResumeIndexObject"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.resume.arn}/index.html"]
  }

  statement {
    sid       = "InvalidateResumeDistribution"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.deploy_cloudfront_distribution_id}"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "github-actions-deploy-least-privilege"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

# ─── OUTPUT ──────────────────────────────────────────────────────────────────
#
# Set this value as the GitHub Actions repository variable AWS_DEPLOY_ROLE_ARN
# (Settings -> Secrets and variables -> Actions -> Variables). The workflow reads
# it via vars.AWS_DEPLOY_ROLE_ARN so the ARN is never committed to the repo.

output "github_actions_deploy_role_arn" {
  description = "ARN of the OIDC deploy role. Set as repo variable AWS_DEPLOY_ROLE_ARN."
  value       = aws_iam_role.github_actions_deploy.arn
}