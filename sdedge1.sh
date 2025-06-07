#!/bin/bash
export SDWNS  # needs to be defined in calling shell
export SIID="$NSID1" # $NSID1, only for OSM, to be defined in calling shell

export NETNUM=1  # used to select external networks (set to 2 for sdedge2)

# CUSTUNIP: the ip address for the home side of the tunnel
export CUSTUNIP="10.255.0.2"

# CUSTPREFIX: the customer private prefix
export CUSTPREFIX="10.20.1.0/24"

# VNFTUNIP: the ip address for the vnf side of the tunnel
export VNFTUNIP="10.255.0.1"

# VCPEPUBIP: the public ip address for the vcpe
export VCPEPUBIP="10.100.1.1"

# VCPEGW: the default gateway for the vcpe
export VCPEGW="10.100.1.254"

# VCPEPRIVIP: IP privada por defecto para el vCPE
VCPEPRIVIP="192.168.255.254"

# CUSTGW: IP privada por defecto para el router del cliente
CUSTGW="192.168.255.253"

# K8SGW: Router por defecto inicial en k8s (calico)
K8SGW="169.254.1.1"

# HELM SECTION
./k8s_sdedge_start.sh