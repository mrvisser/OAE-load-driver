#! /bin/bash
lib/env.sh

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "Usage: $0 <relative snapshot directory>"

SNAPSHOT_DIR=$1

[[ "$SNAPSHOT_DIR" != .* ]] || die "Snapshot directory should not use dot-notation for relative paths."
[[ "$SNAPSHOT_DIR" != /* ]] || die "Snapshot directory should be relative."

echo -n "Download snapshot files (these will be large)? (y/n): "
read DOWNLOAD

if [ "$DOWNLOAD" = "y" ]
then
  echo "Downloading all snapshot data to ./$SNAPSHOT_DIR"
  mkdir -p $SNAPSHOT_DIR
fi

echo ''
echo ''
echo "===[Taking 'store' snapshot in APP1:/tmp/$SNAPSHOT_DIR/store.tar.gz]================================================="
echo "Prepare APP1:/tmp/$SNAPSHOT_DIR..."
ssh -t $EC2_OAE_APP1 "sudo rm -r /tmp/$SNAPSHOT_DIR"
ssh -t $EC2_OAE_APP1 "sudo su - sakaioae -c 'mkdir -p /tmp/$SNAPSHOT_DIR/store'"
echo "Copy store files..."
ssh -t $EC2_OAE_APP1 "sudo su - sakaioae -c 'cp -r /usr/local/sakaioae/store/* /tmp/$SNAPSHOT_DIR/store'"
echo "Package store files..."
ssh -t $EC2_OAE_APP1 "sudo su - sakaioae -c 'cd /tmp/$SNAPSHOT_DIR; tar -cf store.tar store'"
echo "GZip store files..."
ssh -t $EC2_OAE_APP1 "sudo su - sakaioae -c 'gzip --best /tmp/$SNAPSHOT_DIR/store.tar'"

if [ "$DOWNLOAD" = "y" ]
then
  echo 'Downloading file bodies snapshot...'
  sftp $EC2_OAE_APP1:/tmp/$SNAPSHOT_DIR/store.tar.gz
  mv store.tar.gz $SNAPSHOT_DIR
fi

echo ''
echo ''
echo "===[Taking database snapshot in POSTGRES:/tmp/$SNAPSHOT_DIR/oae.tar.gz]================================================="
echo "Prepare POSTGRES:/tmp/$SNAPSHOT_DIR..."
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo rm -r /tmp/$SNAPSHOT_DIR"
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo su - sakaioae -c 'mkdir /tmp/$SNAPSHOT_DIR'"
echo "Using pg_dump to dump database..."
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo su - sakaioae -c 'pg_dump -f /tmp/$SNAPSHOT_DIR/oae.tar -F t -h $EC2_OAE_POSTGRES -U nakamura -w'"
echo "GZip database dump..."
ssh -t $EC2_OAE_POSTGRES -p 2022 "sudo su - sakaioae -c 'gzip --best /tmp/$SNAPSHOT_DIR/oae.tar'"

if [ "$DOWNLOAD" = "y" ]
then
  echo 'Downloading database snapshot'
  sftp -P 2022 $EC2_OAE_POSTGRES:/tmp/$SNAPSHOT_DIR/oae.tar.gz
  mv oae.tar.gz $SNAPSHOT_DIR
fi

echo ''
echo ''
echo "===[Taking Solr snapshot in SOLR:/tmp/$SNAPSHOT_DIR/index.tar]================================================="
echo "Prepare SOLR:/tmp/$SNAPSHOT_DIR..."
ssh -t $EC2_OAE_SOLR -p 2022 "sudo rm -r /tmp/$SNAPSHOT_DIR"
ssh -t $EC2_OAE_SOLR -p 2022 "sudo su - sakaioae -c 'mkdir -p /tmp/$SNAPSHOT_DIR/index'"
echo "Copying Solr indexes..."
ssh -t $EC2_OAE_SOLR -p 2022 "sudo su - sakaioae -c 'cp -r /usr/local/solr/home0/data/index/* /tmp/$SNAPSHOT_DIR/index'"
echo "Package Solr indexes..."
ssh -t $EC2_OAE_SOLR -p 2022 "sudo su - sakaioae -c 'cd /tmp/$SNAPSHOT_DIR; tar -cf index.tar index'"
echo "GZip Solr indexes..."
ssh -t $EC2_OAE_SOLR -p 2022 "sudo su - sakaioae -c 'gzip --best /tmp/$SNAPSHOT_DIR/index.tar'"

if [ "$DOWNLOAD" = "y" ]
then
  echo 'Downloading Solr index snapshot'
  sftp -P 2022 $EC2_OAE_SOLR:/tmp/index.tar.gz
  mv index.tar.gz $SNAPSHOT_DIR
fi

echo ''
echo ''
echo 'Snapshot complete.'
echo ''