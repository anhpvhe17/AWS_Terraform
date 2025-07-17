############################
# Locals
############################
locals {
  glue_script_s3_path = "glue-scripts/batch_csv_to_parquet.py" # relative in module; uploaded below
}

############################
# S3 object: upload Glue script
############################
# Requires that you've created the data bucket already (aws_s3_bucket.data_bucket)
resource "aws_s3_object" "glue_job_script" {
  bucket = aws_s3_bucket.data_bucket.bucket
  key    = local.glue_script_s3_path
  source = "${path.module}/glue_scripts/batch_csv_to_parquet.py"
  etag   = filemd5("${path.module}/glue_scripts/batch_csv_to_parquet.py")
  content_type = "text/x-python"
}

############################
# IAM Role for Glue
############################
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_service_role" {
  name               = "AWSGlueServiceRole-ETL"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  tags = {
    Name = "Glue ETL Role"
  }
}

############################
# IAM Policy: S3 access + logs + Glue defaults
############################
data "aws_iam_policy_document" "glue_access" {
  statement {
    sid     = "S3AccessDataAndLogs"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.data_bucket.arn,
      "${aws_s3_bucket.data_bucket.arn}/*",
      aws_s3_bucket.log_bucket.arn,
      "${aws_s3_bucket.log_bucket.arn}/*",
    ]
  }

  statement {
    sid     = "CloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # Glue needs access to its own resources
  statement {
    sid     = "GlueBasic"
    actions = [
      "glue:Get*",
      "glue:Create*",
      "glue:Update*",
      "glue:Delete*",
      "glue:Batch*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_access_policy" {
  name   = "GlueETLAccess"
  policy = data.aws_iam_policy_document.glue_access.json
}

resource "aws_iam_role_policy_attachment" "glue_access_attach" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

############################
# Glue Job
############################
resource "aws_glue_job" "batch_csv_to_parquet" {
  name     = "batch-csv-to-parquet"
  role_arn = aws_iam_role.glue_service_role.arn

  glue_version = "4.0"        # Spark 3
  number_of_workers = 2
  worker_type       = "G.1X"  # change as needed

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.data_bucket.bucket}/${local.glue_script_s3_path}"
    python_version  = "3"
  }

  # Default args; can be overridden at run time
  default_arguments = {
    "--job-language"        = "python"
    "--SOURCE_PATH"         = "s3://${aws_s3_bucket.data_bucket.bucket}/raw/"
    "--TARGET_PATH"         = "s3://${aws_s3_bucket.data_bucket.bucket}/curated/"
    "--PARTITION_COL"       = "ingest_date"
    "--TempDir"             = "s3://${aws_s3_bucket.log_bucket.bucket}/glue/tmp/"
    "--enable-metrics"      = "true"
    "--enable-glue-datacatalog" = "true"
    "--job-bookmark-option" = "job-bookmark-enable"
  }

  max_retries = 1

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Environment = "Production"
    Project     = "AWS_Terraform"
  }
}
