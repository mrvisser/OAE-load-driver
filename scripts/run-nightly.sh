#! /bin/bash
lib/env.sh

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
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mkdir -p $RESULTS_DIR/tsung'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'cd ~/profiles/nightly; tsung -f tsung.xml -l $RESULTS_DIR/tsung start'"

# The generated tsung output directory is tough to crack. Get it using 'ls'
TSUNG_OUT=`ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'ls $RESULTS_DIR/tsung'"`
TSUNG_OUT="$RESULTS_DIR/tsung/$TSUNG_OUT"

echo 'Assembling the results...'
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mkdir -p $RESULTS_DIR/app1/telemetry $RESULTS_DIR/app1/perf4j $RESULTS_DIR/solr0/admin $RESULTS_DIR/db0'"

# Tsung -- just unpack from the unnecessary date-named directory; then run tsung_stats.pl
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'mv $TSUNG_OUT/* $RESULTS_DIR/tsung; rmdir $TSUNG_OUT'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'cd $RESULTS_DIR/tsung; tsung_stats.pl'"

# App
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp $EC2_OAE_APP1:/usr/local/sakaioae/gc.log $RESULTS_DIR/app1'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp $EC2_OAE_APP1:/var/log/sakaioae/error.log $RESULTS_DIR/app1'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon.css http://$EC2_OAE_APP1:8080/system/resmon/resmon.css'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon-raw.xml http://$EC2_OAE_APP1:8080/system/telemetry'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/app1/telemetry/resmon-raw.xsl http://$EC2_OAE_APP1:8080/system/resmon/resmon.xsl'"

# The resource references for the XSL and CSS files are absolute. Fix them so they are relative.
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'sed s/\\\\/system\\\\/resmon\\\\/resmon/resmon/ < $RESULTS_DIR/app1/telemetry/resmon-raw.xml > $RESULTS_DIR/app1/telemetry/resmon.xml'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'sed s/\\\\/system\\\\/resmon\\\\/resmon/resmon/ < $RESULTS_DIR/app1/telemetry/resmon-raw.xsl > $RESULTS_DIR/app1/telemetry/resmon.xsl'"

#Solr
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp -P 2022 $EC2_OAE_SOLR:/usr/local/sakaioae/tomcat/gc.log $RESULTS_DIR/solr0'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/solr-admin.css http://$EC2_OAE_SOLR:8080/solr/admin/solr-admin.css'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/stats.xml http://$EC2_OAE_SOLR:8080/solr/admin/stats.jsp'"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'wget -O $RESULTS_DIR/solr0/admin/stats.xsl http://$EC2_OAE_SOLR:8080/solr/admin/stats.xsl'"

#Postgres
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo cp /var/lib/pgsql/9.1/pgstartup.log /tmp; sudo chmod +r /tmp/pgstartup.log"
ssh -t $EC2_OAE_DRIVER "sudo su - ec2-user -c 'scp -P 2022 $EC2_OAE_POSTGRES:/tmp/pgstartup.log $RESULTS_DIR/db0'"


# TODO: Perf4j logs