variable "aws_region" {
  default = "ca-central-1"
}

variable "bucket_name" {
  default = "ravjotduhra-cloud-resume"
}

variable "lambda_function_name" {
  default = "cloud-resume-counter"
}

variable "dynamodb_table_name" {
  default = "cloud-resume-visitor-count"
}

# When true, the OIDC deploy role additionally trusts the `oidc-smoke-test`
# branch ref so the assume-role path can be validated before the first real
# merge to main. Keep false in steady state; flip to true only during the
# OIDC smoke test, then flip back. Never widens to a wildcard.
variable "enable_oidc_smoke_test" {
  type    = bool
  default = false
}