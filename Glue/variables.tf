variable "AWS_DEFAULT_REGION" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "data_bucket_name" {
  description = "S3 bucket for data storage"
  type        = string
}

variable "log_bucket_name" {
  description = "S3 bucket for Glue temporary data and logs"
  type        = string
}

variable "glue_script_local_path" {
  description = "Local path to Glue script (e.g., scripts/csv_to_parquet.py)"
  type        = string
}

variable "glue_script_s3_path" {
  description = "S3 path (key) where Glue script will be uploaded"
  type        = string
}
