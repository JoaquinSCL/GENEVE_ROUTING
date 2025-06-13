#!/bin/bash
export SDWNS  # needs to be defined in calling shell
export SIID="$NSID2" # $NSID1, only for OSM, to be defined in calling shell

export NETNUM=2  # used to select external networks (set to 2 for sdedge2)

# CUSTUNIP: the ip address for the home side of the tunnel
export CUSTUNIP="10.255.0.2"

# CUSTPREFIX: the customer private prefix
export CUSTPREFIX="10.20.2.0/24"

# CUSTGW: the default gateway for the customer side
export CUSTGW="10.20.0.2"

# CUSTPREFIXEXT: the customer private prefix
export CUSTPREFIXEXT="10.20.1.0/24"

# CUSTGWEXT: the default gateway for the customer side
export CUSTGWEXT="10.20.0.1"

# VNFTUNIP: the ip address for the vnf side of the tunnel
export VNFTUNIP="10.255.0.1"

# VCPEPUBIP: the public ip address for the vcpe
export VCPEPUBIP="10.100.2.1"

# VCPEPUBIPEXT: the public ip address for the vcpe
export VCPEPUBIPEXT="10.100.1.1"

# VCPEPUBIPEXT: the public ip address for the vcpe in the other side of the tunnel
export VCPEPUBPREFIXEXT="10.100.1.0/24"

# HIPINT: the public ip address for the host of the other headquarters
export HIPINT="10.20.2.2"

# HIPEXT: the public ip address for the host of the other headquarters
export HIPEXT="10.20.1.2"

# TIPINT: the public ip address for the host of the other headquarters
export TIPINT="10.20.2.200"

# TIPEXT: the public ip address for the host of the other headquarters
export TIPEXT="10.20.1.200"

# VCPEGW: the default gateway for the vcpe
export VCPEGW="10.100.2.254"

# VCPEPRIVIP: IP privada por defecto para el vCPE
export VCPEPRIVIP="192.168.255.254"

# GEN1IP: the public ip address for geneve1 interface
export GEN1IP="10.100.169.2"

# K8SGW: Router por defecto inicial en k8s (calico)
export K8SGW="169.254.1.1"

# HELM SECTION
./k8s_sdedge_start.sh