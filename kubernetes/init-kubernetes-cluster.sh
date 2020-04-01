#! /bin/bash

set -uexo pipefail

CONFIG="/tmp/k8s.yaml"
POD_CIDR="10.244.0.0/16"
SVC_CIDR="10.96.0.0/12"
MASTER_IP=`hostname -I | cut -d' ' -f 1`

kubeadm config print init-defaults --component-configs KubeProxyConfiguration  > ${CONFIG}

# hostname must resolve ipaddress and resolve address not 127.0.0.1
sed -i "s|1.2.3.4|${MASTER_IP}|g" ${CONFIG}
sed -i 's|mode: ""|mode: ipvs|g' ${CONFIG}
sed -i "/serviceSubnet:/a\  nodeSubnet: ${POD_CIDR}" $CONFIG

kubeadm init --config ${CONFIG}

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

wget https://docs.projectcalico.org/v3.11/manifests/calico.yaml
sed -i "s|192.168.0.0/16|${POD_CIDR}|g" calico.yaml
kubectl apply -f calico.yaml
rm -f calico.yaml

TOKEN=$(kubeadm token list | tail -n 1 | cut -d' ' -f 1)
SHA256_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

JUMP_CMD="kubeadm join $MASTER_IP:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$SHA256_HASH"
echo "run this cmd on node $JUMP_CMD"
