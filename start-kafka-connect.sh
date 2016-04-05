#!/bin/bash

if [[ -z "$CLASSPATH" ]]; then
    export CLASSPATH="${KAFKA_HOME}/connectors/*"
fi

if [[ ${KAFKA_CONNECT_MODE} == 'standalone' ]]; then
	BIN_EXEC=connect-standalone
	CONFIG_FILE=connect-standalone.properties

	CONNECTOR_NAME=${CONNECTOR_NAME:-elasticsearch}

	if [[ ${CONNECTOR_NAME} == 'elasticsearch' ]]; then

	  cat /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/connectors/connect-elasticsearch.properties.template | sed \
      -e "s|{{ELASTICSEARCH_ADDRESS}}|${ELASTICSEARCH_ADDRESS:-elasticsearch}|g" \
      -e "s|{{KAFKA_HOME}}|${KAFKA_HOME}|g" \
      -e "s|{{GEO_IP_DIRECTORY}}|/usr/local/share/GeoIP|g" \
       > /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/connectors/connect-elasticsearch.properties
	fi

	cat /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}.template | sed \
	  -e "s|{{KAFKA_ADDRESS}}|${KAFKA_ADDRESS:-kafka}|g" \
   > /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}-new.properties

   exec /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/bin/${BIN_EXEC}.sh /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}-new.properties /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/connectors/connect-${CONNECTOR_NAME}.properties

elif [[ ${KAFKA_CONNECT_MODE} == 'distributed' ]]; then
	BIN_EXEC=connect-distributed
	CONFIG_FILE=connect-distributed.properties

	ZOOKEEPER_ADDRESS=${ZOOKEEPER_ADDRESS:-zookeeper}

    #create topics for distributing offset and connectors settings
    CONFIG_STORAGE_TOPIC=${CONFIG_STORAGE_TOPIC:-kafka-connect-config-storage}
    OFFSET_STORAGE_TOPIC=${OFFSET_STORAGE_TOPIC:-kafka-connect-offset-storage}

    $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER_ADDRESS/kafka0.8:2181 --replication-factor 3 --partition 1 --topic ${CONFIG_STORAGE_TOPIC}
    $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER_ADDRESS/kafka0.8:2181 --replication-factor 3 --partition 50 --topic ${OFFSET_STORAGE_TOPIC}

    cat /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}.template | sed \
    -e "s|{{CONFIG_STORAGE_TOPIC}}|${CONFIG_STORAGE_TOPIC}|g" \
    -e "s|{{OFFSET_STORAGE_TOPIC}}|${OFFSET_STORAGE_TOPIC}|g" \
    -e "s|{{KAFKA_ADDRESS}}|${KAFKA_ADDRESS:-kafka}|g" \
    -e "s|{{CONNECT_ADVERTISED_HOSTNAME}}|${CONNECT_ADVERTISED_HOSTNAME:-$THIS_IP}|g" \
    > /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}-new.properties

    exec /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/bin/${BIN_EXEC}.sh /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/${CONFIG_FILE}-new.properties

else
	echo "Execution mode not valid"
	exit
fi





