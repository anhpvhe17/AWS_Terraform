provider "aws" {
  region = var.AWS_DEFAULT_REGION
}

# ------------------------
# Upload Glue Script to S3
# ------------------------
resource "aws_s3_object" "glue_job_script" {
  bucket = var.data_bucket_name
  key    = "${var.glue_script_s3_path}"
  source = var.glue_script_local_path
  etag   = filemd5(var.glue_script_local_path)
}

# ------------------------
# IAM Role for Glue
# ------------------------
resource "aws_iam_role" "glue_service_role" {
  name = "GlueBatchServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# ------------------------
# Glue Policy Document
# ------------------------
data "aws_iam_policy_document" "glue_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.data_bucket_name}",
      "arn:aws:s3:::${var.data_bucket_name}/*",
      "arn:aws:s3:::${var.log_bucket_name}",
      "arn:aws:s3:::${var.log_bucket_name}/*"
    ]
  }

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_policy" {
  name   = "GlueBatchPolicy"
  policy = data.aws_iam_policy_document.glue_access.json
}

resource "aws_iam_role_policy_attachment" "glue_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}

# ------------------------
# Glue Job
# ------------------------
resource "aws_glue_job" "batch_csv_to_parquet" {
  name     = "csv-to-parquet-job"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.data_bucket_name}/${var.glue_script_s3_path}"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"          = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"        = ""
    "--SOURCE_PATH"           = "s3://${var.data_bucket_name}/raw/"
    "--TARGET_PATH"           = "s3://${var.data_bucket_name}/curated/"
    "--TempDir"               = "s3://${var.log_bucket_name}/glue/tmp/"
  }

  max_retries = 1
  glue_version = "4.0"
}
