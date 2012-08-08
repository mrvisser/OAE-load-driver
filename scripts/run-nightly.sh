#!/bin/bash

source lib/env.sh

# Amount of time to sleep (in seconds) after the Nakamura server startup has begun.
SLEEP=15
RUN_ID=`date '+%Y%m%d-%H_%M_%S'`
RESULTS_DIR="/var/www/html/load_testing_results/$RUN_ID"

if [ "$1" != "auto" ]
then
  echo '********'
  echo '* Running nightly performance test. Steps:'
  echo '* '
  echo '*   1. Run ./data-refresh.sh to clean all data and restore (Will take a while)'
  echo "*   2. Pause for $SLEEP seconds to allow the app server to finish starting up"
  echo '*   3. Remote into driver machine as ec2-user, and execute tsung test at ~/profiles/nightly/tsung.xml'
  echo '*   4. Package up all logging and profiling information into the output directory'
  echo '* '
  echo '********'
  echo '';
  echo "Results will be stored in: $RESULTS_DIR"
  echo '';
  echo 'Press any key to continue...'
  read KEY
fi

./data-refresh.sh

echo "Sleeping for $SLEEP seconds..."
sleep $SLEEP

echo 'Starting Tsung test...'
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mkdir -p $RESULTS_DIR/tsung'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'cd ~/profiles/nightly; tsung -f tsung.xml -l $RESULTS_DIR/tsung start'"

# The generated tsung output directory is tough to crack. Get it using 'ls'. 'sed' is used to trim an annoying \r character at the end of the output.
TSUNG_OUT=`ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'ls $RESULTS_DIR/tsung'" | sed 's/[^a-zA-Z0-9_-]//g'`
TSUNG_OUT="$RESULTS_DIR/tsung/$TSUNG_OUT"

echo 'Assembling the results...'
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mkdir -p $RESULTS_DIR/app1/telemetry $RESULTS_DIR/app1/perf4j $RESULTS_DIR/solr0/admin $RESULTS_DIR/db0'"

## Tsung

# Ditch Tsung's own date-based directory for ours
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mv $TSUNG_OUT/* $RESULTS_DIR/tsung; rmdir $TSUNG_OUT'"

# Replace the internal EC2 hosts with human-readable ones. I don't think these are supposed to change..
APP0=ip-10-168-9-8.us-west-1.compute.internal
APP1=ip-10-168-249-50.us-west-1.compute.internal
SOLR0=ip-10-176-66-219.us-west-1.compute.internal
DB0=ip-10-177-9-70.us-west-1.compute.internal
PREVIEW=ip-10-176-194-68.us-west-1.compute.internal
APACHE=ip-10-168-199-125.us-west-1.compute.internal

ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mv $RESULTS_DIR/tsung/tsung.log $RESULTS_DIR/tsung/tsung-raw.log'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'cat $RESULTS_DIR/tsung/tsung-raw.log | sed s/$APP0/app0/g | sed s/$APP1/app1/g | sed s/$SOLR0/solr0/g | sed s/$DB0/db0/g | sed s/$PREVIEW/preview/g | sed s/$APACHE/apache/g > $RESULTS_DIR/tsung/tsung.log'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'cd $RESULTS_DIR/tsung; tsung_stats.pl'"

## App1

# Logs
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp $EC2_OAE_APP1:/usr/local/sakaioae/gc.log $RESULTS_DIR/app1'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp $EC2_OAE_APP1:/usr/local/sakaioae/Perf4J* $RESULTS_DIR/app1'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp $EC2_OAE_APP1:/var/log/sakaioae/error.log $RESULTS_DIR/app1'"

# Telemetry
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon.css http://$EC2_OAE_APP1:8080/system/resmon/resmon.css'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon-raw.xml http://$EC2_OAE_APP1:8080/system/telemetry'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon-raw.xsl http://$EC2_OAE_APP1:8080/system/resmon/resmon.xsl'"

# The resource references for the XSL and CSS files are absolute. Fix them so they are relative.
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'sed s/\\\\/system\\\\/resmon\\\\/resmon/resmon/ < $RESULTS_DIR/app1/telemetry/resmon-raw.xml > $RESULTS_DIR/app1/telemetry/resmon.xml'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'sed s/\\\\/system\\\\/resmon\\\\/resmon/resmon/ < $RESULTS_DIR/app1/telemetry/resmon-raw.xsl > $RESULTS_DIR/app1/telemetry/resmon.xsl'"

## Solr
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp -P 2022 $EC2_OAE_SOLR:/usr/local/sakaioae/tomcat/gc.log $RESULTS_DIR/solr0'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/solr-admin.css http://$EC2_OAE_SOLR:8080/solr/admin/solr-admin.css'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/stats.xml http://$EC2_OAE_SOLR:8080/solr/admin/stats.jsp'"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/stats.xsl http://$EC2_OAE_SOLR:8080/solr/admin/stats.xsl'"

## Postgres
ssh -t -t $EC2_OAE_POSTGRES -p 2022 "sudo cp /var/lib/pgsql/9.1/pgstartup.log /tmp; sudo chmod +r /tmp/pgstartup.log"
ssh -t -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp -P 2022 $EC2_OAE_POSTGRES:/tmp/pgstartup.log $RESULTS_DIR/db0'"
