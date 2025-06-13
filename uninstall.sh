#!/bin/bash

set -u # to verify variables are defined
: $SDWNS

# HELM SECTION
for NETNUM in {1..2}
do
  for VNF in server
  do
    helm -n $SDWNS uninstall $VNF$NETNUM 
  done
done

microk8s kubectl delete deployments --all

sudo vnx -f vnx/sdedge_nfv.xml -P