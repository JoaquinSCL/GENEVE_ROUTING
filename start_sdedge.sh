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
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW
: $VCPEPRIVIP
: $CUSTGW
: $K8SGW

if [[ ! $VSERV =~ "-serverchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <server_deployment_id>: $VSERV"
    exit 1
fi

SERV_EXEC="$KUBECTL exec -n $SDWNS $VSERV --"

# ## 1. En VNF:server configurar reglas, IPs y rutas
echo "## 1. En VNF:server configurar reglas, IPs y rutas"

$SERV_EXEC ifconfig net1 10.100.1.1/24
$SERV_EXEC ifconfig net2 10.200.1.1/24
$SERV_EXEC ip link add name geneve0 type geneve external dstport 6081
$SERV_EXEC ip link set geneve0 up
$SERV_EXEC ip link add name geneve1 type geneve external dstport 6084
$SERV_EXEC ip link set geneve1 up

$SERV_EXEC tc qdisc add dev geneve0 ingress
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 10 \
    flower geneve_opts 0FF01:80:11111111 \
    action tunnel_key unset \
    action mirred egress redirect dev net3
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 10 \
    flower geneve_opts 0FF01:80:22222222 \
    action tunnel_key unset \
    action mirred egress redirect dev geneve1
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 10 \
    flower geneve_opts 0FF01:80:44444444 \
    action tunnel_key unset \
    action mirred egress redirect dev net2
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 11 \
    protocol arp \
    flower arp_tip 10.100.3.3 \
    action tunnel_key unset \
    action mirred egress redirect dev net3
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 11 \
    protocol arp \
    flower arp_tip 10.100.3.4 \
    action tunnel_key unset \
    action mirred egress redirect dev geneve1
$SERV_EXEC tc filter add dev geneve0 parent ffff: prio 11 \
    protocol arp \
    flower arp_tip 10.200.1.3 \
    action tunnel_key unset \
    action mirred egress redirect dev net2

$SERV_EXEC tc qdisc add dev geneve1 ingress
$SERV_EXEC tc filter add dev geneve1 parent ffff: prio 10 \
    flower geneve_opts 0FF01:80:33333333 \
    action tunnel_key unset \
    action mirred egress redirect dev geneve0         
$SERV_EXEC tc filter add dev geneve1 parent ffff: prio 11 \
    protocol arp \
    matchall \
    action tunnel_key unset \
    action mirred egress redirect dev geneve0

$SERV_EXEC ip addr add 10.100.3.1/24 dev geneve0
$SERV_EXEC ip addr add 10.100.3.2/24 dev geneve1

$SERV_EXEC tc qdisc add dev geneve0 root handle 1: prio
$SERV_EXEC tc filter add dev geneve0 parent 1: \
    protocol ip \
    flower src_ip 10.100.3.3  \
    action tunnel_key set \
    src_ip 10.100.1.1 \
    dst_ip 10.100.1.2 \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:11111111 \
    pass
$SERV_EXEC tc filter add dev geneve0 parent 1: \
    protocol ip \
    flower src_ip 10.100.3.4 \
    action tunnel_key set \
    src_ip 10.100.1.1 \
    dst_ip 10.100.1.2 \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:22222222 \
    pass
$SERV_EXEC tc filter add dev geneve0 parent 1: \
    protocol ip \
    flower src_ip 10.200.1.3 \
    action tunnel_key set \
    src_ip 10.100.1.1 \
    dst_ip 10.100.1.2 \
    dst_port 6081 \
    id 1000 \
    geneve_opts 0FF01:80:44444444 \
    pass
$SERV_EXEC tc filter add dev geneve0 parent 1: \
    protocol arp \
    matchall \
    action tunnel_key set \
    src_ip 10.100.1.1 \
    dst_ip 10.100.1.2 \
    dst_port 6081 \
    id 1000 \
    action pass

$SERV_EXEC tc qdisc add dev geneve1 root handle 2: prio
$SERV_EXEC tc filter add dev geneve1 parent 2: \
    protocol ip \
    flower dst_ip 10.100.3.4 \
    action tunnel_key set \
    src_ip 10.200.1.1 \
    dst_ip 10.200.1.2 \
    dst_port 6084 \
    id 1000 \
    geneve_opts 0FF01:80:33333333 \
    pass
$SERV_EXEC tc filter add dev geneve1 parent 2: \
    protocol arp \
    matchall \
    action tunnel_key set \
    src_ip 10.200.1.1 \
    dst_ip 10.200.1.2 \
    dst_port 6084 \
    id 1000 \
    pass

$SERV_EXEC tc qdisc add dev net3 ingress
$SERV_EXEC tc filter add dev net3 parent ffff: \
    protocol ip \
    flower src_ip 10.100.3.3 \
    action mirred egress redirect dev geneve0
$SERV_EXEC tc filter add dev net3 parent ffff: \
    protocol arp \
    matchall \
    action mirred egress redirect dev geneve0

$SERV_EXEC tc qdisc add dev net2 ingress
$SERV_EXEC tc filter add dev net2 parent ffff: \
    protocol ip \
    flower src_ip 10.200.1.3 \
    action mirred egress redirect dev geneve0
$SERV_EXEC tc filter add dev net2 parent ffff: \
    protocol arp \
    flower arp_sip 10.200.1.3 \
    action mirred egress redirect dev geneve0
    

# ## 4. En VNF:cpe agregar un bridge y configurar IPs y rutas
# echo "## 4. En VNF:cpe agregar un bridge y configurar IPs y rutas"
# $CPE_EXEC ovs-vsctl add-br brint
# $CPE_EXEC ifconfig brint $VCPEPRIVIP/24
# $CPE_EXEC ifconfig net$NETNUM $VCPEPUBIP/24
# $CPE_EXEC ip route del 0.0.0.0/0 via $K8SGW
# $CPE_EXEC ip route add 0.0.0.0/0 via $VCPEGW
# $CPE_EXEC ip route add $CUSTPREFIX via $CUSTGW

# ## 5. En VNF:cpe activar NAT para dar salida a Internet
# echo "## 5. En VNF:cpe activar NAT para dar salida a Internet"
# $CPE_EXEC /vnx_config_nat brint net$NETNUM