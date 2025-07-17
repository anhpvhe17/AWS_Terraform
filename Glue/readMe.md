AWS Glue Batch ETL Job
This project provisions an AWS Glue ETL job using Terraform to process raw data stored in Amazon S3 and transform it into a curated format for analytics.

✅ Features
Source: Reads raw CSV files from S3.

Transform: Cleans and standardizes data (column normalization, optional date partition).

Target: Writes partitioned Parquet files back to S3 for optimized querying.

Infrastructure as Code: Managed via Terraform (Glue job, IAM roles, policies, and optional scheduled trigger).

Customizable: Pass job arguments for source path, target path, and partition column.

📂 Project Structure
bash
Copy
Edit
AWS_Terraform/
├── main.tf                  # Terraform provider and S3 buckets
├── glue.tf                  # Glue job + IAM role + optional trigger
├── glue_scripts/
│   └── batch_csv_to_parquet.py  # Glue ETL script
├── variables.tf
├── outputs.tf
└── README.md
⚙️ How It Works
Upload the ETL script to S3.

Deploy resources using Terraform (terraform apply).

Run the Glue job manually or via scheduled trigger.

Job reads from s3://<bucket>/raw/ → writes to s3://<bucket>/curated/ in Parquet format, partitioned by ingest_date.

🔑 Requirements
AWS account with Glue enabled.

Terraform installed locally.

IAM permissions to create Glue, IAM roles, S3 objects.