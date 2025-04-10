FROM debezium/connect:2.7.1.Final

# Set up directories and install path for confluent CLI
ENV CONFLUENT_CLI_VERSION=4.9.0
ENV CONFLUENT_CLI_INSTALL_DIR=/kafka/connect/confluent-cli
ENV PATH="${CONFLUENT_CLI_INSTALL_DIR}/:$PATH"
ENV PLUGIN_DIR=/kafka/connect
ENV CONNECT_WORKER_CONFIG=/kafka/config.orig/connect-distributed.properties

RUN mkdir -p $PLUGIN_DIR $CONFLUENT_CLI_INSTALL_DIR

# Install Confluent CLI
RUN ARCH=$(uname -m) && \
    [ "$ARCH" = "aarch64" ] && ARCH="arm64" || [ "$ARCH" = "x86_64" ] && ARCH="amd64" && \
    curl -L --fail -O https://packages.confluent.io/confluent-cli/archives/${CONFLUENT_CLI_VERSION}/confluent_linux_${ARCH}.tar.gz && \
    tar xzf confluent_linux_${ARCH}.tar.gz -C /tmp/ && \
    mv /tmp/confluent/confluent $CONFLUENT_CLI_INSTALL_DIR/ && \
    rm -rf /tmp/confluent confluent_linux_${ARCH}.tar.gz

# Install Avro converter plugin (fix: add worker-config file)
RUN confluent connect plugin install \
    --force \
    --plugin-directory $PLUGIN_DIR \
    --worker-configurations $CONNECT_WORKER_CONFIG \
    confluentinc/kafka-connect-avro-converter:7.5.0


# Install confluent s3 sink connector
RUN confluent connect plugin install \
    --force \
    --plugin-directory $PLUGIN_DIR \
    --worker-configurations $CONNECT_WORKER_CONFIG \
    confluentinc/kafka-connect-s3:latest
# Set plugin path (for Kafka Connect to pick up plugins)
# ENV CONNECT_PLUGIN_PATH=$PLUGIN_DIR

CMD ["start"]