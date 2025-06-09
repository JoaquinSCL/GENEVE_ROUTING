#!/bin/bash
  
# Requires the following variables
# SDWNS: cluster namespace in the cluster vim
# NETNUM: used to select external networks
# CUSTUNIP: the ip address for the customer side of the tunnel
# VNFTUNIP: the ip address for the vnf side of the tunnel
# VCPEPUBIP: the public ip address for the vcpe
# VCPEGW: the default gateway for the vcpe

set -u # to verify variables are defined
: $SDWNS
: $NETNUM
: $CUSTUNIP
: $CUSTPREFIX
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW
: $VCPEPRIVIP
: $CUSTGW
: $K8SGW
: $HIPEXT
: $TIPEXT
: $VCPEPUBIPEXT

export KUBECTL="microk8s kubectl"

## 0. Instalación
echo "## 0. Instalación de las vnfs"

echo "### 0.1 Limpieza (ignorar errores)"

for vnf in server
do
  helm -n $SDWNS uninstall $vnf$NETNUM 
done

for i in {1..15}; do echo -n "."; sleep 1; done
echo ''

echo "### 0.2 Creación de contenedores"

for vnf in server 
do
  echo "#### $vnf$NETNUM"
  helm -n $SDWNS install $vnf$NETNUM helm/cpechart/ --values helm/cpechart/values.yaml --set deployment.network="accessnet$NETNUM\,extnet$NETNUM\,mplswan"
done

for i in {1..30}; do echo -n "."; sleep 1; done
echo ''

export VSERV="deploy/server$NETNUM-cpechart"

./start_sdedge.sh

