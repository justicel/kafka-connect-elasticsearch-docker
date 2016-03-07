#!/usr/bin/env bash

COMPONENT="vimond-kafka-connect"


tar -cvf "temp.tar" -C ansible/src/user/dist .
curl -i -u"$ARTIFACTORY_USER:$ARTIFACTORY_PASSWORD" -T temp.tar \
    "$ARTIFACTORY_CONTEXTURL/ansible/$COMPONENT/$2/$COMPONENT-$2.tar;git_sha=$1;version=$2;build.name=$3"
