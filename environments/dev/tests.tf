

resource "aws_s3_bucket_object" "test" {
  bucket = aws_s3_bucket.nik-dem-ecs.bucket
  key    = "test"
  content = "This is a test object"
}

output "bucket_id" {
  value = aws_s3_bucket.nik-dem-ecs.id
}

output "bucket_arn" {
  value = aws_s3_bucket.nik-dem-ecs.arn
}
