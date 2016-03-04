FROM alpine:3.2

MAINTAINER Matteo Remo Luzzi <matteo@vimond.com> 

# Install cURL
RUN apk --update add curl ca-certificates tar && \
    curl -Ls https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk > /tmp/glibc-2.21-r2.apk && \
    apk add --allow-untrusted /tmp/glibc-2.21-r2.apk

# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 45
ENV JAVA_VERSION_BUILD 14
ENV JAVA_PACKAGE       jdk

ENV KAFKA_VERSION "0.9.0.0"
ENV SCALA_VERSION_DOWNLOAD "2.11.0"
ENV SCALA_VERSION "2.11"
ENV SCALA_HOME /usr/share/scala

# Download and unarchive Java
RUN mkdir /opt && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie"\
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    | tar -xzf - -C /opt &&\
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk &&\
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/lib/plugin.jar \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so
   

# Set environment
ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin

#Install scala
RUN apk add bash && \
    cd "/tmp" && \
    wget "http://downloads.typesafe.com/scala/${SCALA_VERSION_DOWNLOAD}/scala-${SCALA_VERSION_DOWNLOAD}.tgz" && \
    tar xzf "scala-${SCALA_VERSION_DOWNLOAD}.tgz" && \
    mkdir "${SCALA_HOME}" && \
    rm "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/bin/"*.bat && \
    mv "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/bin" "/tmp/scala-${SCALA_VERSION_DOWNLOAD}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    rm -rf "/tmp/"*

RUN apk add jq

#Donwload and install kafka
ADD download-kafka.sh /tmp/download-kafka.sh
RUN chmod +x -R /tmp
RUN /tmp/download-kafka.sh
RUN tar xf /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt

EXPOSE 8083

ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

RUN mkdir ${KAFKA_HOME}/connectors

ADD start-kafka-connect.sh /usr/bin/start-kafka-connect.sh
ADD config/connect-standalone.properties /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/connect-standalone.properties.template
ADD config/connect-distributed.properties /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/config/connect-distributed.properties.template

ADD lib/connectors ${KAFKA_HOME}/connectors

CMD start-kafka-connect.sh
    