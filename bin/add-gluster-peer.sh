#!/bin/bash

# Exit status = 0 means the peer was successfully joined
# Exit status = 1 means the peer will be added when another container joins the cluster (because of the replica)
# Exit status = 255 means there was an error while joining the peer to the cluster

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

PEER=$1

if [ -z "${PEER}" ]; then
   echo "=> ERROR: I was supposed to add a new gluster peer to the cluster but no IP was specified, doing nothing ..."
   exit 255
fi

echo "=> Checking if I can reach gluster container ${PEER} ..."
if ping -c 10 ${PEER} >/dev/null 2>&1; then
   echo "=> Gluster container ${PEER} is alive"
else
   echo "*** Could not reach gluster master container ${PEER} - exiting ..."
   exit 255
fi

# Check if peer container is already part of the cluster
if gluster peer status | grep ${PEER} >/dev/null; then
   echo "=> Peer container ${PEER} is already part of this cluster, nothing to do ..."
   exit 0
fi

# Check how many peers are already joined in the cluster
NUMBER_OF_PEERS=`gluster peer status | awk '{print $4}'`
NUMBER_OF_REPLICAS=$((NUMBER_OF_PEERS+2))
if [ ${NUMBER_OF_PEERS} -eq 0 ]; then
   # In this case, there is no peers on this cluster yet
   if gluster volume list | grep "^${GLUSTER_VOL}$" >/dev/null; then
      echo "=> The volume ${GLUSTER_VOL} is already created, we are not supposed to reach this point so this is a fatal error - Exiting ..."
      exit 1
   else
   echo "=> Creating GlusterFS volume ${GLUSTER_VOL}..."
   MY_IP=`ip add | grep brd | grep inet | awk '{print $2}' | sed "s/\/.*//g"`
   if [ -z ${MY_IP} ]; then
      echo "*** ERROR getting this container IP - Exiting ..."
      exit 1
   fi
   gluster volume create ${GLUSTER_VOL} replica ${NUMBER_OF_REPLICAS} ${MY_IP}:${GLUSTER_BRICK_PATH} ${PEER}:${GLUSTER_BRICK_PATH} force

   sleep 1

   # Start the volume
   if gluster volume status ${GLUSTER_VOL} >/dev/null; then
      echo "=> The volume ${GLUSTER_VOL} is already started, we are not supposed to reach this point so this is a fatal error - Exiting ..."
   else
      echo "=> Starting GlusterFS volume ${GLUSTER_VOL}..."
      gluster volume start ${GLUSTER_VOL}
   fi
else
   # In this case, the cluster is already set up and we have to add a new brick
   echo "=> Adding peer ${PEER} to the cluster ..."
   gluster volume add-brick ${GLUSTER_VOL} replica ${NUMBER_OF_REPLICAS} ${PEER}:${GLUSTER_BRICK_PATH}
fi

exit 0
