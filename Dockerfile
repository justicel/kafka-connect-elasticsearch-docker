FROM anapsix/alpine-java

MAINTAINER Matteo Remo Luzzi <matteo@vimond.com> 


ENV KAFKA_VERSION "0.9.0.0"
ENV SCALA_VERSION_DOWNLOAD "2.11.0"
ENV SCALA_VERSION "2.11"
ENV SCALA_HOME /usr/share/scala

# Set environment
ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin
ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

#Install scala
RUN cd "/tmp" && \
    wget "http://downloads.typesafe.com/scala/${SCALA_VERSION_DOWNLOAD}/scala-${SCALA_VERSION_DOWNLOAD}.tgz" && \
    tar xzf "scala-${SCALA_VERSION_DOWNLOAD}.tgz" && \
    mkdir "${SCALA_HOME}" && \
    rm "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/bin/"*.bat && \
    mv "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/bin" "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    rm -rf "/tmp/"*


RUN apk update \
    && apk add jq \
    && apk add zlib-dev \
    && apk add curl-dev \
    && apk add sudo \
    && apk add build-base

#download and install maxmind geoupdate
ENV \
    GEOIP_USERID=999999 \
    GEOIP_LICENSE=000000000000 \
    GEOIP_PRODUCT_LINE="ProductIds GeoLite2-City GeoLite2-Country GeoLite-Legacy-IPv6-City GeoLite-Legacy-IPv6-Country 506 517 533" \
    GEO_IP_DIRECTORY=/usr/local/share/GeoIP

ADD config/GeoIP.conf $GEO_IP_DIRECTORY/GeoIP.conf

WORKDIR /tmp

RUN wget "https://github.com/maxmind/geoipupdate/releases/download/v2.2.2/geoipupdate-2.2.2.tar.gz" \
    && tar xzf "geoipupdate-2.2.2.tar.gz" \
    && cd "geoipupdate-2.2.2" \
    && ./configure && make && sudo make install \

    # Configure maxmind
    && sed -i "s/YOUR_USER_ID_HERE/$GEOIP_USERID/g" $GEO_IP_DIRECTORY/GeoIP.conf \
    && sed -i "s/YOUR_LICENSE_KEY_HERE/$GEOIP_LICENSE/g" $GEO_IP_DIRECTORY/GeoIP.conf \
    && sed -i "s/^ProductIds.*$/$GEOIP_PRODUCT_LINE/g" $GEO_IP_DIRECTORY/GeoIP.conf \
    && geoipupdate -f $GEO_IP_DIRECTORY/GeoIP.conf -v \

    # Download the geo lite ip database
    && wget "http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz" \
    && gunzip -c GeoIP.dat.gz > $GEO_IP_DIRECTORY/GeoIP.dat \
    && rm GeoIP.dat.gz \


    # Setup a cron job that updates the geo database
    && echo \
    'geoipupdate -f /etc/GeoIP.conf 2>&1 | logger\n'\ >> /etc/periodic/weekly/geoip \
    && chmod +x /etc/periodic/weekly/geoip \
    && rm -rf "/tmp/"*


VOLUME $GEO_IP_DIRECTORY

#Donwload and install kafka
ADD download-kafka.sh /tmp/download-kafka.sh
RUN chmod +x -R /tmp
RUN /tmp/download-kafka.sh
RUN tar xzf /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt

ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

RUN mkdir ${KAFKA_HOME}/connectors

ADD start-kafka-connect.sh /usr/bin/start-kafka-connect.sh
ADD config/connect-standalone.properties /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/connect-standalone.properties.template
ADD config/connect-distributed.properties /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/connect-distributed.properties.template

ADD lib/connectors ${KAFKA_HOME}/connectors

#JVM and JMX option

ENV KAFKA_JVM_PERFORMANCE_OPTS -server -XX:+UseG1GC \
                                       -XX:MaxGCPauseMillis=20 \
                                       -XX:InitiatingHeapOccupancyPercent=35 \
                                       -XX:+DisableExplicitGC \
                                       -Djava.awt.headless=true

ENV KAFKA_JMX_OPTS -Dcom.sun.management.jmxremote \
                   -Dcom.sun.management.jmxremote.port=9010 \
                   -Dcom.sun.management.jmxremote.rmi.port=9010 \
                   -Dcom.sun.management.jmxremote.local.only=false \
                   -Dcom.sun.management.jmxremote.authenticate=false \
                   -Dcom.sun.management.jmxremote.ssl=false

EXPOSE 8160
EXPOSE 9010

ENV SERVICE_8160_NAME kafka-connect-elasticsearch-docker
ENV SERVICE_8160_TAGS "haproxy-lb-http,service,haproxy-backend"

ENV SERVICE_9010_NAME kafka-connect-elasticsearch-docker-jmx
ENV SERVICE_9010_TAGS "tcp,private"

CMD start-kafka-connect.sh
    