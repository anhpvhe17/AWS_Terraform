import sys
import pyspark.sql.functions as F
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext

# ------------------------------------------------------------------
# Args from Glue job parameters
# ------------------------------------------------------------------
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "SOURCE_PATH",     # s3 path to raw data (folder)
        "TARGET_PATH",     # s3 path to output curated data
        "PARTITION_COL",   # e.g., ingest_date
    ],
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

source_path = args["SOURCE_PATH"]
target_path = args["TARGET_PATH"]
partition_col = args["PARTITION_COL"]

# ------------------------------------------------------------------
# Read CSV (assuming header + infer schema; tune for prod)
# ------------------------------------------------------------------
df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")  # better: define schema explicitly
    .csv(source_path)
)

# ------------------------------------------------------------------
# Example transform: trim strings, add ingest_date if missing
# ------------------------------------------------------------------
# Add today's date if PARTITION_COL not present
if partition_col not in df.columns:
    df = df.withColumn(partition_col, F.current_date())

# Standardize column names (lowercase, underscore)
for old in df.columns:
    new = old.strip().lower().replace(" ", "_")
    if new != old:
        df = df.withColumnRenamed(old, new)

# Ensure partition column is string or date; cast to date string
if partition_col in df.columns:
    df = df.withColumn(partition_col, F.col(partition_col).cast("date"))

# ------------------------------------------------------------------
# Write to Parquet partitioned
# ------------------------------------------------------------------
(
    df.write
    .mode("overwrite")  # consider "append" for prod
    .partitionBy(partition_col)
    .format("parquet")
    .save(target_path)
)

job.commit()
