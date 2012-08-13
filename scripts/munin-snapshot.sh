#! /bin/sh
source lib/env.sh

ssh $EC2_OAE_APP0 "bash -s" < lib/munin-package.sh
sftp $EC2_OAE_APP0:/tmp/munin-dumps/latest.tar.gz
