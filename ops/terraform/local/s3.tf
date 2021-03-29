resource "aws_s3_bucket" "local_bucket" {
  bucket = "test-local-bucket"
  acl    = "private"

  tags = {
    Name        = "local bucket"
    Environment = "local"
  }
}
