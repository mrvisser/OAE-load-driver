#!/bin/bash

#
# Host variables used to log into each machine
#

# Note these direct app server hosts can change :(
export EC2_OAE_APP0=ec2-50-18-147-148.us-west-1.compute.amazonaws.com
export EC2_OAE_APP1=ec2-204-236-168-81.us-west-1.compute.amazonaws.com

export EC2_OAE_APP=OAE-AppServers-365563856.us-west-1.elb.amazonaws.com
export EC2_OAE_SOLR=OAE-SOLR-426995740.us-west-1.elb.amazonaws.com
export EC2_OAE_POSTGRES=OAE-Postgres-566174176.us-west-1.elb.amazonaws.com
export EC2_OAE_PREVIEW=OAE-Preview-2008250595.us-west-1.elb.amazonaws.com
export EC2_OAE_DRIVER=oae-loader.sakaiproject.org
export EC2_OAE_HTTPD=oae-performance.sakaiproject.org
