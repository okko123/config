#!/bin/bash
set -uexo pipefail

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

if [ `/usr/sbin/getenforce` == "Enforcing" ];then
    /usr/sbin/setenforce 0
    grep -q "=enforcing" /etc/selinux/config && sed -i "s|^SELINUX=enforcing$|SELINUX=disabled|g" /etc/selinux/config
fi
yum install -y kubelet kubeadm kubectl docker ipvsadm ipset --disableexcludes=kubernetes
systemctl enable --now kubelet docker

lsmod | grep br_netfilter
if [ "$?" != "0" ];then
    modprobe br_netfilter
fi
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
