.PHONY: build-connect build-spark up down logs

build-connect:
	docker buildx build --platform linux/amd64 -t spark/kafka-connect:latest ./kafka-connect --load

build-spark:
	docker compose build spark-master spark-worker spark-history-server

up:
	docker compose up -d

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=100
