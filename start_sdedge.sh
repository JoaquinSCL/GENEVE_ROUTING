#!/bin/bash

set -u # to verify variables are defined
: $KUBECTL
: $SDWNS
: $NETNUM
: $VSERV
: $CUSTUNIP
: $CUSTPREFIX
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW
: $K8SGW
: $HIPEXT
: $TIPEXT
: $HIPINT
: $VCPEPUBIPEXT

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

$SERV_EXEC ip route del 0.0.0.0/0 via $K8SGW
$SERV_EXEC ip route add 0.0.0.0/0 via $VCPEGW dev net2

$SERV_EXEC sudo ip link add br0 type bridge
$SERV_EXEC sudo ip link set br0 up
$SERV_EXEC sudo ip link set geneve0 master br0
$SERV_EXEC sudo ip addr add 192.168.255.254/24 dev br0
 
$SERV_EXEC ip route add $CUSTPREFIX via $CUSTGATEWAY
$SERV_EXEC sudo ip route add $CUSTGATEWAY dev net1

$SERV_EXEC tc qdisc add dev geneve0 clsact
# Redirige tráfico Geneve con opción 0x11111111 desde geneve0 hacia geneve1
echo "# Redirige tráfico Geneve con opción 0x11111111 desde geneve0 hacia geneve1"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:11111111 \
    action mirred egress redirect dev geneve1
# Redirige tráfico Geneve con opción 0x22222222 desde geneve0 hacia net3
echo "# Redirige tráfico Geneve con opción 0x22222222 desde geneve0 hacia net3"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:22222222 \
    action tunnel_key unset \
    action mirred egress redirect dev net3
# Redirige tráfico Geneve con opción 0x44444444 desde geneve0 hacia br0
echo "# Redirige tráfico Geneve con opción 0x44444444 desde geneve0 hacia br0"
$SERV_EXEC tc filter add dev geneve0 ingress prio 10 \
    flower geneve_opts 0FF01:80:44444444 \
    action tunnel_key unset

$SERV_EXEC tc qdisc add dev geneve1 clsact
# Redirige tráfico Geneve con opción 0x33333333 desde geneve1 hacia geneve1 del site contrario
echo "# Redirige tráfico Geneve con opción 0x33333333 desde geneve1 hacia geneve1 del site contrario"
$SERV_EXEC tc filter add dev geneve1 egress \
    matchall \
    action tunnel_key set \
    src_ip $VCPEPUBIP \
    dst_ip $VCPEPUBIPEXT \
    dst_port 6084 \
    id 1000 \
    geneve_opts 0FF01:80:33333333 
# Redirige tráfico Geneve desde geneve1 hacia geneve0
echo "# Redirige tráfico Geneve desde geneve1 hacia geneve0"
$SERV_EXEC tc filter add dev geneve1 ingress \
    flower geneve_opts 0FF01:80:33333333 \
    action mirred egress redirect dev geneve0

$SERV_EXEC tc qdisc add dev net3 clsact
# Redirige IP desde $TIPEXT en net3 hacia geneve0
echo "# Redirige IP desde $TIPEXT en net3 hacia geneve0"
$SERV_EXEC tc filter add dev net3 ingress \
    matchall \
    action mirred egress redirect dev geneve0

# Encapsula y permite IP desde $HIPEXT desde geneve0 hacia geneve0 con opción 0x11111111
echo "# Encapsula y permite IP desde $HIPEXT desde geneve0 hacia geneve0 con opción 0x11111111"
$SERV_EXEC tc filter add dev geneve0 egress prio 1 \
    protocol ip \
    flower src_ip $HIPEXT \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:11111111
# Encapsula y permite IP desde $TIPEXT desde geneve0 hacia geneve0 con opción 0x22222222
echo "# Encapsula y permite IP desde $TIPEXT desde geneve0 hacia geneve0 con opción 0x22222222"
$SERV_EXEC tc filter add dev geneve0 egress prio 2 \
    protocol ip \
    flower src_ip $TIPEXT \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:22222222
# Encapsula y permite IP desde 192.168.255.250 desde geneve0 hacia geneve0 con opción 0x44444444
echo "# Encapsula y permite IP desde internet desde geneve0 hacia geneve0 con opción 0x44444444"
$SERV_EXEC tc filter add dev geneve0 egress prio 5 \
    matchall \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:44444444
# Encapsula y permite ARP hacia 192.168.255.253
echo "# Encapsula y permite ARP hacia 192.168.255.253"
$SERV_EXEC tc filter add dev geneve0 egress prio 3 \
    protocol arp \
    flower arp_tip 192.168.255.253 \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:44444444
# Encapsula y permite todo el tráfico ARP restante
echo "# Encapsula y permite todo el tráfico ARP restante"
$SERV_EXEC tc filter add dev geneve0 egress prio 4 \
    protocol arp \
    matchall \
    action tunnel_key set \
    src_ip $VNFTUNIP \
    dst_ip $CUSTUNIP \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:22222222

# ## 2. En VNF:server configurar NAT
echo "## 2. En VNF:server configurar NAT"
$SERV_EXEC sed -i 's/\r$//' vnx_config_nat
$SERV_EXEC ./vnx_config_nat br0 net2

$SERV_EXEC iptables -t mangle -A POSTROUTING -o net2 -p ip -j TTL --ttl-set 32