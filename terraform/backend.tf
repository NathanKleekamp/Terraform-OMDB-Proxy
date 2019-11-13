terraform {
  backend "s3" {
    # Cannot use variables or local values here
    bucket = "bbp-omdb-serverless"
    key = "terraform/state"
    region = "us-east-1"
  }
}

resource "aws_iam_role" "s3_backend_role" {
  name = "serverless_omdb_terraform_backend_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3_backend_policy" {
  name = "serverless_omdb_terraform_backend_policy"
  description = "Terraform backend policy for S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${var.s3_bucket}"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::${var.s3_bucket}/${var.terraform_state_dir}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "terraform_backend_attach" {
  role = "${aws_iam_role.s3_backend_role.name}"
  policy_arn = "${aws_iam_policy.s3_backend_policy.arn}"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.s3_bucket}"
    key = "${var.terraform_state_dir}"
    region = "${var.aws_region}"
  }
}
