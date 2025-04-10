# /opt/spark/apps/read_delta.py

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("ReadDeltaExample") \
    .getOrCreate()

path = "s3a://datalake/delta/people"

df = spark.read.format("delta").load(path)

df.show()