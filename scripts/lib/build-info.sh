#!/bin/bash
source lib/env.sh

REPO_URL=http://repository-sakai-oae.forge.cloudbees.com/snapshot

if [ -z "$VERSION" ]
then
  VERSION="1.5.0"
fi

# First get the latest snapshot metadata
curl $REPO_URL/org/sakaiproject/nakamura/org.sakaiproject.nakamura.app/$VERSION-SNAPSHOT/maven-metadata.xml > /tmp/metadata-$VERSION.xml

TIMESTAMP=`sed -n 's|.*<timestamp>\(.*\)</timestamp>.*|\1|p' < /tmp/metadata-$VERSION.xml`
BUILDNUMBER=`sed -n 's|.*<buildNumber>\(.*\)</buildNumber>.*|\1|p' < /tmp/metadata-$VERSION.xml`

export REPO_URL
export VERSION
export TIMESTAMP
export BUILDNUMBER
