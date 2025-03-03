resource "aws_s3_bucket" "s3-dem" {
  bucket = "my-s3-dem-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3-dem" {
  bucket = aws_s3_bucket.s3-dem.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "test" {
  bucket = aws_s3_bucket.s3-dem.bucket
  key    = "test"
  content = "This is a test object"
}

output "bucket_id" {
  value = aws_s3_bucket.s3-dem.id
}

output "bucket_arn" {
  value = aws_s3_bucket.s3-dem.arn
}
