#!/bin/bash

source lib/env.sh

VERSION=$1
REPO_URL=http://repository-sakai-oae.forge.cloudbees.com/snapshot

if [ -z "$VERSION" ]
then
  VERSION="1.5.0"
fi

# First get the latest snapshot metadata
curl $REPO_URL/org/sakaiproject/nakamura/org.sakaiproject.nakamura.app/$VERSION-SNAPSHOT/maven-metadata.xml > /tmp/metadata-$VERSION.xml

TIMESTAMP=`sed -n 's|.*<timestamp>\(.*\)</timestamp>.*|\1|p' < /tmp/metadata-$VERSION.xml`
BUILDNUMBER=`sed -n 's|.*<buildNumber>\(.*\)</buildNumber>.*|\1|p' < /tmp/metadata-$VERSION.xml`

echo $TIMESTAMP
echo $BUILDNUMBER

curl $REPO_URL/org/sakaiproject/nakamura/org.sakaiproject.nakamura.app/$VERSION-SNAPSHOT/org.sakaiproject.nakamura.app-$VERSION-$TIMESTAMP-$BUILDNUMBER.jar > /tmp/latest.jar

scp /tmp/latest.jar $EC2_OAE_APP1:/tmp/latest.jar
ssh -t -t $EC2_OAE_APP1 "sudo mv /tmp/latest.jar /usr/local/sakaioae/jars/latest.jar"
ssh -t -t $EC2_OAE_APP1 "sudo rm -f /usr/local/sakaioae/sakaioae.jar; sudo ln -s /usr/local/sakaioae/jars/latest.jar /usr/local/sakaioae/sakaioae.jar"
