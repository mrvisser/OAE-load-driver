#!/bin/sh
lib/env.sh

# Data Setup:
#
# postgres:~/.oae/scripts/drop_all_tables.sql - SQL script to drop all tables in the nakamura database
# postgres:~/.pgpass                          - The postgres password file. Example contents: *:*:nakamura:ironchef
#

echo ''
echo ''
echo '===[Stopping app server 1]================================================='
ssh -t $EC2_OAE_APP1 'sudo /etc/init.d/sakaioae stop'

echo ''
echo ''
echo '===[Stopping Solr server]================================================='
ssh -t $EC2_OAE_SOLR -p 2022 'sudo /etc/init.d/tomcat stop'

echo ''
echo ''
echo '===[Drop all postgres data]================================================='
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo su - sakaioae -c 'psql -U nakamura -h $EC2_OAE_POSTGRES -w -f ~/.oae/scripts/drop_all_tables.sql'"

echo ''
echo ''
echo '===[Stopping postgres]================================================='
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo /etc/init.d/postgresql-9.1 stop"

echo ''
echo ''
echo '===[Delete all solr data]================================================='
ssh -t $EC2_OAE_SOLR -p 2022 'sudo rm -rf /usr/local/solr/home0/data/index/*'

echo ''
echo ''
echo '===[Delete all active-mq data]================================================='
ssh -t $EC2_OAE_APP1 'sudo rm -rf /usr/local/sakaioae/activemq-data/*'

echo ''
echo ''
echo '===[Delete all file bodies]================================================='
ssh -t $EC2_OAE_APP1 'sudo su - sakaioae -c "rm -rf /usr/local/sakaioae/store/*"'

echo ''
echo ''
echo '===[Delete all logs]================================================='
ssh -t $EC2_OAE_APP1 "sudo rm /usr/local/sakaioae/gc.log"
ssh -t $EC2_OAE_APP1 "sudo rm -r /var/log/sakaioae/*"
ssh -t $EC2_OAE_SOLR -p 2022 "sudo rm /usr/local/sakaioae/tomcat/gc.log"
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo rm /var/lib/pgsql/9.1/pgstartup.log"
