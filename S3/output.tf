output "data_bucket_name" {
  description = "Name of the data bucket"
  value       = aws_s3_bucket.data_bucket.bucket
}

output "log_bucket_name" {
  description = "Name of the log bucket"
  value       = aws_s3_bucket.log_bucket.bucket
}
