#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

join-cluster.sh &
/usr/bin/supervisord
