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