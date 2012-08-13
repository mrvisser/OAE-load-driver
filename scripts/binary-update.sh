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
ssh $EC2_OAE_APP1 "sudo su - sakaioae -c 'mv /tmp/latest.jar /usr/local/sakaioae/jars/latest.jar'"
ssh $EC2_OAE_APP1 "sudo su - sakaioae -c 'rm -f /usr/local/sakaioae/sakaioae.jar; ln -s /usr/local/sakaioae/jars/latest.jar /usr/local/sakaioae/sakaioae.jar'"

