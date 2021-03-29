resource "aws_iam_role" "tf_role" {
  name = "TerraformRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    name = "TerraformRole"
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.local_bucket.arn}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PubObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.local_bucket.arn}"
    ]
  }
}

resource "aws_iam_policy" "tf_s3" {
  name        = "TerraformS3Access"
  description = "Terraform S3 access."
  policy      = data.aws_iam_policy_document.s3.json
}
