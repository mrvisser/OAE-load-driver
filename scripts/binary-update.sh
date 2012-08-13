#!/bin/bash

source lib/env.sh

if [ -z "$REPO_URL" ]
then
  source lib/build-info.sh
fi

# Note that REPO_URL, VERSION, TIMESTAMP, and BUILDNUMBER are all determined in lib/build-info.sh

echo "Updating to snapshot: $VERSION-$TIMESTAMP-$BUILDNUMBER..."
ssh -t -t $EC2_OAE_APP1 "curl $REPO_URL/org/sakaiproject/nakamura/org.sakaiproject.nakamura.app/$VERSION-SNAPSHOT/org.sakaiproject.nakamura.app-$VERSION-$TIMESTAMP-$BUILDNUMBER.jar > /tmp/latest.jar" 
ssh -t -t $EC2_OAE_APP1 "sudo mv /tmp/latest.jar /usr/local/sakaioae/jars/latest.jar"
ssh -t -t $EC2_OAE_APP1 "sudo rm -f /usr/local/sakaioae/sakaioae.jar; sudo ln -s /usr/local/sakaioae/jars/latest.jar /usr/local/sakaioae/sakaioae.jar"
