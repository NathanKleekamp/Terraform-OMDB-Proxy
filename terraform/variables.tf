variable "s3_bucket" {
  type = string
  default = "bbp-omdb-serverless"
}

variable "terraform_state_dir" {
  type = string
  default = "terraform/state"
}

variable "aws_region" {
  type = "string"
  default = "us-east-1"
}

variable "app_version" {
  type = string

  # The Lambda version to build against
  default = "1.0.7"
}
