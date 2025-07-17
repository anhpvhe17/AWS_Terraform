# Provider AWS
provider "aws" {
  region = var.AWS_DEFAULT_REGION 
}
 
### Tạo bucket chứa logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-log-storage-bucket-anhpvhe"
 
  # Cấu hình block public access (khuyến nghị)
  force_destroy = true # Dùng để xóa bucket nếu Terraform bị destroy
  lifecycle {
    prevent_destroy = false # Cho phép destroy khi cần
  }
 
  tags = {
    Name        = "Logs Bucket"
    Environment = "Production"
  }
}
 
### Thêm bucket policy cho bucket chứa logs (cho phép ghi Access Logs)
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
 
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "logging.s3.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.log_bucket.arn}/*", # Cho phép ghi vào toàn bộ bucket log
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"       = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
 
### Tạo bucket dữ liệu chính (bật Access Logging)
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-first-s3-bucket-anhpvhe"
 
  force_destroy = true # Dùng để xóa bucket nếu Terraform bị destroy
 
  tags = {
    Name        = "Data Bucket"
    Environment = "Production"
  }
}
 
### Set up logging for the data bucket
resource "aws_s3_bucket_logging" "data_bucket_logging" {
  bucket        = aws_s3_bucket.data_bucket.id               # Target data bucket
  target_bucket = aws_s3_bucket.log_bucket.id                # Logs are written to the log bucket
  target_prefix = "my-first-s3-bucket-logs/"                 # Prefix for log objects
}