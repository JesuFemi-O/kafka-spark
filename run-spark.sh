#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "❌ Usage: ./run-spark.sh <path-to-pyspark-app>"
  exit 1
fi

APP_PATH="$1"

DELTA_VERSION=2.2.0

COMMON_SPARK_ARGS="
  --packages io.delta:delta-core_2.12:${DELTA_VERSION},org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-bundle:1.11.1026
  --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension
  --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog
  --conf spark.hadoop.fs.s3a.endpoint=http://minio:9000
  --conf spark.hadoop.fs.s3a.access.key=minioadmin
  --conf spark.hadoop.fs.s3a.secret.key=minioadmin
  --conf spark.hadoop.fs.s3a.path.style.access=true
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
"

echo "🚀 Running Spark app: $APP_PATH"
docker compose exec spark-master \
  spark-submit $COMMON_SPARK_ARGS "$APP_PATH"