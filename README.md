# kafka-connect-elasticsearch-docker
Docker version of Kafka connect with the elasticsearch sink plugin. It uses apline linux as base image for keeping the final image size small.

## How to run it
Execute <code>docker run -p 8083:8083 -p 7203:7203 --env KAFKA_ADDRESS=kafka_addr --env ELASTICSEARCH_ADDRESS=es_addr --env ZOOKEEPER_ADDRESS=zk_addr --env KAFKA_CONNECT_MODE=standalone --name connect kafka-connect</code>
or <code>docker-compose up</code>
## Configuration
Is it possible to specify the following variables:
<ul>
  <li>KAFKA_CONNECT_MODE: valid values are <i>standalone</i> and <i>distributed</i></li>
  <li>CONNECT_ADVERTISED_HOSTNAME: hostname of the machine where the container runs. If not set it is resolved in the private ip of the machine</li>
  <li>ZOOKEEPER_ADDRESS: address of zookeeper instance running. It is used in distributed execution mode</li>
  <li>KAFKA_ADDRESS: address of the kafka cluster used by kafka connect</li>
  <li>ELASTICSEARCH_ADDRESS: address of the elasticsearch where to write data</li>
  <li>CONNECTOR_NAME: name of the connector to execute in standalone mode. Defaults to elasticsearch</li>
</ul>

## Assumption
Even though this docker image of kafka-connect runs by default the elasticsearch-sink plugin it is compatible with any other custom plugin. Just place the executable jar file and the properties file of the plugin under lib/conncetors.
The properties file must be renamed as <i>connect-${CONNECTOR_NAME}.properties</i> where ${CONNECTOR_NAME} is the value of the input env variable CONNECTOR_NAME. This is valid only for standalone mode since in distributed mode, the connector properties are injected via REST API
## Standalone vs Distributed
Standalone mode starts immediately the connector while distributed mode requires interaction with Kafka connect rest API for loading and starting the it.
In order to start the connector execute from a HTTP client:
POST kafka-connect-address:8083/connectors -d 
```json
{
    "name": "elasticsearch-sink-connector",
    "config": {
        "connector.class": "com.vimond.elasticsearch_kafka_connector.sink.ElastcisearchSinkConnector",
        "tasks.max": "1",
        "topics": "connect-test-distributed",
        "geo.path": "/opt/kafka_2.11-0.9.0.0/connectors/connect-elasticsearch/maxmind",
        "es.hostsAndPort": "elasticsearch:9300",
        "es.index": "vimond-numbers",
        "es.type": "user-asset_playback-event",
        "es.client.type": "transport",
        "es.cluster.name": "elasticsearch",
        "es.input.json": "true",
        "discovery.zen.ping.multicast.enabled": "false",
        "discovery.zen.ping.unicast.hosts": "machine_ip_address:9200"
    }
}
```
Kafka connect doesn't have a master/slave structure, then every node of the cluster has is own rest interface and can create/delete connectors.
For more information regarding Kafka connect read the official <a href="http://docs.confluent.io/2.0.0/connect/index.html">documentation</a>
