#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ -z ${COREOS_PRIVATE_IPV4} ]; then
   echo "*** ERROR you need to define "-e COREOS_PRIVATE_IPV4=${COREOS_PRIVATE_IPV4}" environment variable - Exiting ..."
   exit 1
fi

join-cluster.sh &
/usr/bin/supervisord
