#!/bin/bash

bin/prepare-k8slab

source ~/.bashrc

sudo vnx -f vnx/sdedge_nfv.xml -P

sudo vnx -f vnx/sdedge_nfv.xml -t

./sdedge1.sh

./sdedge2.sh

echo "Terminado"

microk8s kubectl get all -n rdsv
