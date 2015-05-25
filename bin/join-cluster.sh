#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

function gluster_info() {
   echo "=> Peers in cluster: TODO"
   echo "=> Volumes in cluster: `gluster volume list`"
   echo "=> Mount command: TODO"
}

echo "=> Waiting for glusterd to start..."
sleep 10

# Check if I'm part of the cluster
NUMBER_OF_PEERS=`gluster peer status | awk '{print $4}'`
if [ ${NUMBER_OF_PEERS} -ne 0 ]; then
   # This container is already part of the cluster
   echo "=> This container is already joined with nodes ${GLUSTER_PEERS}, skipping joining ..."
   gluster_info
   exit 0
fi

# Join the cluster - choose a suitable container
ALIVE=0
for PEER in `echo ${GLUSTER_PEERS} | sed "s/,/ /g"`; do
   echo "=> Checking if I can reach gluster container ${PEER} ..."
   if ping -c 10 ${PEER} >/dev/null 2>&1; then
      echo "=> Gluster container ${PEER} is alive"
      ALIVE=1
      break
   else
      echo "*** Could not reach gluster container ${PEER} ..."
   fi 
done

if [ "$ALIVE" == 0 ]; then
   echo "Could not contact any GlusterFS container from this list: ${GLUSTER_PEERS} - Maybe I am the first node in the cluster? Well, I keep waiting for new containers to join me ..."
   exit 0
fi

echo "=> Joining cluster with container ${PEER} ..."
ssh ${SSH_OPTS} ${SSH_USER}@${PEER} "add-gluster-peer.sh ${COREOS_PRIVATE_IPV4}"
if [ $? -eq 0 ]; then
   echo "=> Successfully joined cluster with container ${GLUSTER_PEER} ..."
else
   echo "=> Error joining cluster with container ${GLUSTER_PEER} ..."
fi
