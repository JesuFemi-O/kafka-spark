# Spark + Kafka + MinIO + Delta Lake: Setup Notes and Gotchas

This document outlines the setup, quirks, and best practices for standing up a local streaming data platform using:

- Apache Kafka (with Confluent Platform)
- Kafka Connect with Debezium + Avro + Schema Registry
- MinIO (S3-compatible object store)
- Apache Spark (Standalone Cluster)
- Delta Lake (for transactional storage)

## 💻 System Assumptions
- Docker + Docker Compose installed
- Python 3.10+ with `pip-tools` for Python dependency management
- You're developing on a Mac (especially Apple Silicon) or Linux

---

## 🛠️ Building Images

### Kafka Connect (Debezium + Avro)
**Issue:** On Apple M1/M2, cross-platform compatibility is required.

**Solution:** Build the image _outside_ of Docker Compose using `buildx` to explicitly target `linux/amd64`:

```bash
# Build the custom kafka-connect image
DOCKER_DEFAULT_PLATFORM=linux/amd64 \
  docker buildx build \
  --platform linux/amd64 \
  -t custom/kafka-connect:latest . \
  --load
```

Then, in your `docker-compose.yml`, explicitly set:
```yaml
platform: linux/amd64
```

### Spark Cluster
We created a custom `Dockerfile` under `./spark` to:
- Use Python 3.10
- Install Java 11
- Download and unpack Spark 3.3.1
- Include Hadoop and the AWS SDK for S3A support

We later added the ability to mount local Spark apps during dev, but this can be disabled in prod.

---

## 🧩 Kafka Connect Environment Variable Gotchas

Debezium deviates slightly from Confluent's expected ENV VARs for Connect.

| Purpose | Debezium ENV Var | Confluent-style Alt |
|--------|------------------|---------------------|
| Bootstrap servers | `BOOTSTRAP_SERVERS` | `CONNECT_BOOTSTRAP_SERVERS` |
| Key converter | `KEY_CONVERTER` | `CONNECT_KEY_CONVERTER` |
| Value converter | `VALUE_CONVERTER` | `CONNECT_VALUE_CONVERTER` |
| Config topic | `CONFIG_STORAGE_TOPIC` | `CONNECT_CONFIG_STORAGE_TOPIC` |

We had to use Debezium-style naming (no `CONNECT_` prefix) for some vars to get it working:

```yaml
environment:
  BOOTSTRAP_SERVERS: kafka:9092
  CONFIG_STORAGE_TOPIC: connect-configs
  OFFSET_STORAGE_TOPIC: connect-offsets
  STATUS_STORAGE_TOPIC: connect-status
  KEY_CONVERTER: io.confluent.connect.avro.AvroConverter
  VALUE_CONVERTER: io.confluent.connect.avro.AvroConverter
```

---

## 🪣 MinIO + Delta Lake via Spark

To interact with MinIO via Spark + Delta, we added these JVM-level configurations to `spark-submit`:

```bash
--packages io.delta:delta-core_2.12:2.4.0,org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-bundle:1.11.1026 \
--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
--conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
--conf spark.hadoop.fs.s3a.endpoint=http://minio:9000 \
--conf spark.hadoop.fs.s3a.access.key=minioadmin \
--conf spark.hadoop.fs.s3a.secret.key=minioadmin \
--conf spark.hadoop.fs.s3a.path.style.access=true \
--conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
```

---

## 🚀 Running Spark Jobs

To simplify running Spark apps inside the Docker container, we’ve provided a helper script:

📄 **Script**: [`run-spark.sh`](./run-spark.sh)

make script an executable

```bash
chmod +x run-spark.sh 
```

submit a job!
```bash
./run-spark.sh <path-to-your-spark-app>
```

🔧 Example:
```bash
./run-spark.sh /opt/spark/apps/write_delta.py
```

This script does the following:

- Executes the app using spark-submit inside the spark-master container.

- Automatically loads the required Delta Lake, Hadoop AWS, and AWS SDK packages.

- Injects the necessary Spark configs to write to MinIO using s3a://.


---

## 🪵 Spark Logging Verbosity

Add this to your `spark/conf/log4j2.properties` or `spark-defaults.conf`:

```properties
spark.executor.extraJavaOptions -Dlog4j.configurationFile=file:/opt/spark/conf/log4j2.properties
spark.driver.extraJavaOptions -Dlog4j.configurationFile=file:/opt/spark/conf/log4j2.properties
```

And define `log4j2.properties` to reduce noise:
```properties
status = error
rootLogger.level = WARN
```

---

## 🛠️ Suggested Makefile
```makefile
.PHONY: build-connect build-spark up down logs

build-connect:
	docker buildx build --platform linux/amd64 -t custom/kafka-connect:latest . --load

build-spark:
	docker compose build spark-master spark-worker spark-history-server

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=100
```

---

## ✅ Final Notes

This setup is now capable of:
- Streaming PostgreSQL changes via Debezium
- Serializing using Avro with Schema Registry
- Writing to Delta Lake format in MinIO using Spark
- Local observability via Kafka UI and Spark History Server

Next steps: implement structured streaming jobs, build CDC pipelines, and publish your setup as a clean repo + blog post!

