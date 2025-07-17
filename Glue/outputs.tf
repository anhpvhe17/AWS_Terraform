output "glue_job_name" {
  value = aws_glue_job.batch_csv_to_parquet.name
}

output "glue_script_s3" {
  value = "s3://${var.data_bucket_name}/${var.glue_script_s3_path}"
}
