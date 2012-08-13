#!/bin/bash

DUMP_DIR=/tmp/munin-dumps/`date +%Y-%m-%d-%H%M-%S`
WWW_DIR=/var/www/html/munin

mkdir -p $DUMP_DIR
cd $DUMP_DIR
cp -R $WWW_DIR munin
tar -c munin > munin.tar
gzip -c munin.tar > munin.tar.gz
rm -Rf munin munin.tar
cp munin.tar.gz ../latest.tar.gz