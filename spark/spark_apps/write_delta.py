from pyspark.sql import SparkSession
import os

# MinIO credentials
minio_access_key = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
minio_secret_key = os.getenv("MINIO_SECRET_KEY", "minioadmin")
minio_endpoint = "http://minio:9000"
bucket_name = "datalake"
path = f"s3a://{bucket_name}/delta/people"

# Initialize Spark
spark = SparkSession.builder \
    .appName("Write Delta Table") \
    .config("spark.hadoop.fs.s3a.endpoint", minio_endpoint) \
    .config("spark.hadoop.fs.s3a.access.key", minio_access_key) \
    .config("spark.hadoop.fs.s3a.secret.key", minio_secret_key) \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

# Create sample DataFrame
data = [("Emmanuel", 28), ("Abbie", 27)]
df = spark.createDataFrame(data, ["name", "age"])

# Write to Delta format
df.write.format("delta").mode("overwrite").save(path)

print(f"✅ Delta table written to {path}")
spark.stop()