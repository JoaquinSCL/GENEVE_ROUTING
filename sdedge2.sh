#!/bin/bash
export SDWNS  # needs to be defined in calling shell
export SIID="$NSID2" # $NSID1, only for OSM, to be defined in calling shell

export NETNUM=2  # used to select external networks (set to 2 for sdedge2)

# CUSTUNIP: the ip address for the home side of the tunnel
export CUSTUNIP="10.255.0.2"

# CUSTPREFIX: the customer private prefix
export CUSTPREFIX="10.20.2.0/24"

# IP privada por defecto para el router del cliente
export CUSTGATEWAY="192.168.255.253"

# VNFTUNIP: the ip address for the vnf side of the tunnel
export VNFTUNIP="10.255.0.1"

# VCPEPUBIP: the public ip address for the vcpe
export VCPEPUBIP="10.100.2.1"

# VCPEPUBIPEXT: the public ip address for the vcpe
export VCPEPUBIPEXT="10.100.1.1"

# HIPINT: the public ip address for the host of the other headquarters
export HIPINT="10.20.2.0/25"

# HIPEXT: the public ip address for the host of the other headquarters
export HIPEXT="10.20.1.0/25"

# TIPINT: the public ip address for the host of the other headquarters
export TIPINT="10.20.2.192/28"

# TIPEXT: the public ip address for the host of the other headquarters
export TIPEXT="10.20.1.192/28"

# VCPEGW: the default gateway for the vcpe
export VCPEGW="10.100.2.254"

# K8SGW: Router por defecto inicial en k8s (calico)
export K8SGW="169.254.1.1"

# HELM SECTION
./k8s_sdedge_start.sh