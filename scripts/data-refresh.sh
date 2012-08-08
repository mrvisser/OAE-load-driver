#!/bin/bash
lib/env.sh

# Data Setup:
#
# postgres:~/.oae/scripts/drop_all_tables.sql - SQL script to drop all tables in the nakamura database
# postgres:~/.oae/data/oae.tar                - The data dump to restore into psql
# postgres:~/.pgpass                          - The postgres password file. Example contents: *:*:nakamura:ironchef
# app1:~/.oae/data/store                      - The directory of file bodies to restore
#

# Delete and shut everything down
./data-teardown.sh

echo ''
echo ''
echo '===[Starting PostgreSQL]================================================='
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo /etc/init.d/postgresql-9.1 start"

echo ''
echo ''
echo '===[Restore PostgreSQL]================================================='
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo su - sakaioae -c 'pg_restore -U nakamura -h $EC2_OAE_POSTGRES -w -O -x -d nakamura < ~/.oae/data/oae.tar'"

echo ''
echo ''
echo '===[Restore Solr Indexes]================================================='
ssh -t $EC2_OAE_SOLR -p 2022 "sudo su - sakaioae -c 'cp -R ~/.oae/data/index/* /usr/local/solr/home0/data/index'"

echo ''
echo ''
echo '===[Restore file bodies]================================================='
ssh -t $EC2_OAE_APP1 'sudo su - sakaioae -c "cp -R ~/.oae/data/store/* /usr/local/sakaioae/store"'

echo ''
echo ''
echo '===[Start Solr]================================================='
ssh -t $EC2_OAE_SOLR -p 2022 'sudo /etc/init.d/tomcat start'

echo ''
echo ''
echo '===[Start App Server 1]================================================='
ssh -t $EC2_OAE_APP1 'sudo /etc/init.d/sakaioae start'

echo ''
echo ''
echo 'Done. Give a couple minutes for the server to fully start up.'
echo ''