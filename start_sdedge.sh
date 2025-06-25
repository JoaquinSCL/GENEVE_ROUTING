#!/bin/bash

# Requires the following variables
# KUBECTL: kubectl command
# SDWNS: cluster namespace in the cluster vim
# NETNUM: used to select external networks
# VACC: "pod_id" or "deploy/deployment_id" of the access vnf
# VCPE: "pod_id" or "deploy/deployment_id" of the cpd vnf
# VWAN: "pod_id" or "deploy/deployment_id" of the wan vnf
# CUSTUNIP: the ip address for the customer side of the tunnel
# VNFTUNIP: the ip address for the vnf side of the tunnel
# VCPEPUBIP: the public ip address for the vcpe
# VCPEGW: the default gateway for the vcpe

set -u # to verify variables are defined
: $KUBECTL
: $SDWNS
: $NETNUM
: $VSERV
: $CUSTUNIP
: $CUSTPREFIX
: $CUSTGW
: $CUSTPREFIXEXT
: $CUSTGWEXT
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW
: $VCPEPRIVIP
: $K8SGW
: $HIPEXT
: $TIPEXT
: $HIPINT
: $GEN1IP

if [[ ! $VSERV =~ "-cpechart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <server_deployment_id>: $VSERV"
    exit 1
fi

SERV_EXEC="$KUBECTL exec -n $SDWNS $VSERV --"

# ## 1. En VNF:server configurar reglas, IPs y rutas
echo "## 1. En VNF:server configurar reglas, IPs y rutas"

$SERV_EXEC ip link add name geneve0 type geneve external dstport 6081
$SERV_EXEC ip link set geneve0 up
$SERV_EXEC ip link add name geneve1 type geneve external dstport 6084
$SERV_EXEC ip link set geneve1 up


$SERV_EXEC ifconfig net1 $VNFTUNIP/24
$SERV_EXEC ifconfig net2 $VCPEPUBIP/24
# $SERV_EXEC ip route add $VCPEPUBPREFIXEXT via $VCPEGW dev net2
$SERV_EXEC ip route del 0.0.0.0/0 via $K8SGW
$SERV_EXEC ip route add 0.0.0.0/0 via $VCPEGW dev net2

$SERV_EXEC sudo ip link add brint type bridge
$SERV_EXEC sudo ip link set brint up
$SERV_EXEC sudo ip addr add 192.168.255.254/24 dev brint



$SERV_EXEC tc qdisc add dev geneve0 clsact
# Redirige tráfico Geneve con opción 0x11111111 desde geneve0 hacia geneve1
echo "# Redirige tráfico Geneve con opción 0x11111111 desde geneve0 hacia geneve1"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:11111111 \
    action tunnel_key unset \
    action mirred egress redirect dev geneve1
# Redirige tráfico Geneve con opción 0x22222222 desde geneve0 hacia net3
echo "# Redirige tráfico Geneve con opción 0x22222222 desde geneve0 hacia net3"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:22222222 \
    action tunnel_key unset \
    action mirred egress redirect dev net3
# Redirige tráfico Geneve con opción 0x44444444 desde geneve0 hacia net2
echo "# Redirige tráfico Geneve con opción 0x44444444 desde geneve0 hacia brint"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:44444444 \
    action tunnel_key unset \
    action mirred egress redirect dev brint

$SERV_EXEC tc qdisc add dev geneve1 clsact
# Encapsula y permite IP hacia $HIPEXT desde geneve1 hacia geneve1 con opción 0x33333333
echo "# Encapsula y permite IP hacia $HIPEXT desde geneve1 hacia geneve1 con opción 0x33333333"
$SERV_EXEC tc filter add dev geneve1 egress \
    matchall \
    action tunnel_key set \
    src_ip $VCPEPUBIP \
    dst_ip $VCPEPUBIPEXT \
    dst_port 6084 \
    id 1000 \
    geneve_opts 0FF01:80:33333333 \
    action pass 

# Redirige tráfico Geneve con opción 0x33333333 desde geneve1 hacia geneve0
echo "# Redirige tráfico Geneve con opción 0x33333333 desde geneve1 hacia geneve0"
$SERV_EXEC tc filter add dev geneve1 ingress \
    flower geneve_opts 0FF01:80:33333333 \
    action tunnel_key unset \
    action mirred egress redirect dev geneve0


$SERV_EXEC tc qdisc add dev brint clsact
# Redirige IP desde internet hacia geneve0
$SERV_EXEC tc filter add dev brint ingress \
    matchall \
    action mirred egress redirect dev geneve0

$SERV_EXEC tc qdisc add dev net3 clsact
# Redirige IP desde $TIPEXT en net3 hacia geneve0
echo "# Redirige IP desde $TIPEXT en net3 hacia geneve0"
$SERV_EXEC tc filter add dev net3 ingress \
    matchall \
    action mirred egress redirect dev geneve0

# Encapsula y permite IP hacia $HIPINT desde geneve0 hacia geneve0 con opción 0x11111111
echo "# Encapsula y permite IP hacia $HIPINT desde geneve0 hacia geneve0 con opción 0x11111111"
$SERV_EXEC tc filter add dev geneve0 egress \
    protocol ip \
    flower dst_ip $HIPINT \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:11111111 \
    action pass

# Encapsula y permite IP hacia $TIPINT desde geneve0 hacia geneve0 con opción 0x22222222
echo "# Encapsula y permite IP hacia $TIPINT desde geneve0 hacia geneve0 con opción 0x22222222"
$SERV_EXEC tc filter add dev geneve0 egress \
    matchall \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:22222222 \
    action pass
# Encapsula y permite IP desde 192.168.255.250 desde geneve0 hacia geneve0 con opción 0x44444444
echo "# Encapsula y permite IP desde 8.8.8.8 desde geneve0 hacia geneve0 con opción 0x44444444"
$SERV_EXEC tc filter add dev geneve0 egress \
    protocol ip \
    flower src_ip 8.8.8.8 \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:44444444 \
    action pass


$SERV_EXEC sed -i 's/\r$//' vnx_config_nat
$SERV_EXEC ./vnx_config_nat brint net2

$SERV_EXEC iptables -t mangle -A POSTROUTING -o net2 -p ip -j TTL --ttl-set 32