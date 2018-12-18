#!/bin/bash
# set -ex

HOSTFILE=inv.py
declare -A EtcdArray MasterArray NodeArray SLBArray

# 获取ETCD主机IP
etcd_host=$(python /playbook/${HOSTFILE} | jq -r .etcd.hosts[])
for etcd in ${etcd_host}; do
    hostname=$(python /playbook/${HOSTFILE} | jq -r ._meta.hostvars.\"${etcd}\".hostname)
    EtcdArray["${hostname}"]="${etcd}"
done

# 获取Master主机IP
master_host=$(python /playbook/${HOSTFILE} | jq -r .master.hosts[])
for master in ${master_host}; do
    hostname=$(python /playbook/${HOSTFILE} | jq -r ._meta.hostvars.\"${master}\".hostname)
    MasterArray["${hostname}"]="${master}"
done

# 获取Node主机IP
node_host=$(python /playbook/${HOSTFILE} | jq -r .node.hosts[])
for node in ${node_host}; do
    hostname=$(python /playbook/${HOSTFILE} | jq -r ._meta.hostvars.\"${node}\".hostname)
    NodeArray["${hostname}"]="${node}"
done

# 获取SLB主机IP
loadbalancing=$(python /playbook/${HOSTFILE} | jq -r .slb.hosts[])
for slb in ${loadbalancing}; do
    hostname=$(python /playbook/${HOSTFILE} | jq -r ._meta.hostvars.\"${slb}\".hostname)
    SLBArray["${hostname}"]="${slb}"
done

export VIP=$(python /playbook/${HOSTFILE} | jq -r .all.vars.VIP)
export interface=$(python ${HOSTFILE} | jq -r .all.vars.interface)
export KUBE_APISERVER=$(python ${HOSTFILE} | jq -r .all.vars.KUBE_APISERVER)
export K8S_DIR=/etc/kubernetes
export PKI_DIR=${K8S_DIR}/pki
export ETCD_SSL=/etc/etcd/ssl
export MANIFESTS_DIR=/etc/kubernetes/manifests/

WORKDIR=$(pwd)
cd ssl
ClusterIPCIDR=$(python /playbook/${HOSTFILE} | jq -r .all.vars.ClusterIPCIDR)
sed -i "s#ClusterIPCIDR#${ClusterIPCIDR}#g" kube-proxy.conf

ServiceDNSIP=$(python /playbook/${HOSTFILE} | jq -r .all.vars.ServiceDNSIP)
sed -i "s#ServiceDNSIP#${ServiceDNSIP}#g" kubelet-conf.yml

mkdir -p ${ETCD_SSL} ${PKI_DIR}

echo "==> Create etcd service certificate"
cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare ${ETCD_SSL}/etcd-ca
cfssl gencert \
-ca=${ETCD_SSL}/etcd-ca.pem \
-ca-key=${ETCD_SSL}/etcd-ca-key.pem \
-config=ca-config.json \
-hostname=127.0.0.1,$(xargs -n1<<<${EtcdArray[@]} | sort  | paste -d, -s -) \
-profile=kubernetes \
etcd-csr.json | cfssljson -bare ${ETCD_SSL}/etcd
rm -rf ${ETCD_SSL}/*.csr
cp -ar ${ETCD_SSL}/{etcd-ca-key,etcd-ca,etcd-key,etcd}.pem /playbook/roles/Etcd/files/

echo "==> Create CA certificate"
# Kubernetes CA
cfssl gencert -initca ca-csr.json | cfssljson -bare ${PKI_DIR}/ca

echo "==> Create API Server certificate"
# API Server Certificate
cfssl gencert \
-ca=${PKI_DIR}/ca.pem \
-ca-key=${PKI_DIR}/ca-key.pem \
-config=ca-config.json \
-hostname=10.96.0.1,${VIP},127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.default.svc.cluster.local,$(xargs -n1<<<${MasterArray[@]} | sort  | paste -d, -s -),$(xargs -n1<<<${SLBArray[@]} | sort  | paste -d, -s -) \
-profile=kubernetes \
apiserver-csr.json | cfssljson -bare ${PKI_DIR}/apiserver

echo "==> Create Front Proxy certificate"
# Front Proxy Certificate
cfssl gencert \
-initca front-proxy-ca-csr.json | cfssljson -bare ${PKI_DIR}/front-proxy-ca
cfssl gencert \
-ca=${PKI_DIR}/front-proxy-ca.pem \
-ca-key=${PKI_DIR}/front-proxy-ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
front-proxy-client-csr.json | cfssljson -bare ${PKI_DIR}/front-proxy-client

echo "==> Create Controller Manager certificate"
# Controller Manager Certificate
cfssl gencert \
-ca=${PKI_DIR}/ca.pem \
-ca-key=${PKI_DIR}/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
manager-csr.json | cfssljson -bare ${PKI_DIR}/controller-manager


# controller-manager set cluster
kubectl config set-cluster kubernetes \
--certificate-authority=${PKI_DIR}/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${K8S_DIR}/controller-manager.kubeconfig

# controller-manager set credentials
kubectl config set-credentials system:kube-controller-manager \
--client-certificate=${PKI_DIR}/controller-manager.pem \
--client-key=${PKI_DIR}/controller-manager-key.pem \
--embed-certs=true \
--kubeconfig=${K8S_DIR}/controller-manager.kubeconfig

# controller-manager set context
kubectl config set-context system:kube-controller-manager@kubernetes \
--cluster=kubernetes \
--user=system:kube-controller-manager \
--kubeconfig=${K8S_DIR}/controller-manager.kubeconfig

# controller-manager set default context
kubectl config use-context system:kube-controller-manager@kubernetes \
--kubeconfig=${K8S_DIR}/controller-manager.kubeconfig

echo "==> Create Scheduler certificate"
# Scheduler Certificate
cfssl gencert \
-ca=${PKI_DIR}/ca.pem \
-ca-key=${PKI_DIR}/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
scheduler-csr.json | cfssljson -bare ${PKI_DIR}/scheduler

# scheduler set cluster
kubectl config set-cluster kubernetes \
--certificate-authority=${PKI_DIR}/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${K8S_DIR}/scheduler.kubeconfig

# scheduler set credentials
kubectl config set-credentials system:kube-scheduler \
--client-certificate=${PKI_DIR}/scheduler.pem \
--client-key=${PKI_DIR}/scheduler-key.pem \
--embed-certs=true \
--kubeconfig=${K8S_DIR}/scheduler.kubeconfig

# scheduler set context
kubectl config set-context system:kube-scheduler@kubernetes \
--cluster=kubernetes \
--user=system:kube-scheduler \
--kubeconfig=${K8S_DIR}/scheduler.kubeconfig

# scheduler use default context
kubectl config use-context system:kube-scheduler@kubernetes \
--kubeconfig=${K8S_DIR}/scheduler.kubeconfig

echo "==> Create Admin certificate"
# Admin Certificate
cfssl gencert \
-ca=${PKI_DIR}/ca.pem \
-ca-key=${PKI_DIR}/ca-key.pem \
-config=ca-config.json \
-profile=kubernetes \
admin-csr.json | cfssljson -bare ${PKI_DIR}/admin

# admin set cluster
kubectl config set-cluster kubernetes \
--certificate-authority=${PKI_DIR}/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${K8S_DIR}/admin.kubeconfig

# admin set credentials
kubectl config set-credentials kubernetes-admin \
--client-certificate=${PKI_DIR}/admin.pem \
--client-key=${PKI_DIR}/admin-key.pem \
--embed-certs=true \
--kubeconfig=${K8S_DIR}/admin.kubeconfig

# admin set context
kubectl config set-context kubernetes-admin@kubernetes \
--cluster=kubernetes \
--user=kubernetes-admin \
--kubeconfig=${K8S_DIR}/admin.kubeconfig

# admin set default context
kubectl config use-context kubernetes-admin@kubernetes \
--kubeconfig=${K8S_DIR}/admin.kubeconfig

# Master Kubelet Certificate
for NODE in "${!MasterArray[@]}"; do
    echo "==> Create Master($NODE) Kubelet certificate"
    \cp kubelet-csr.json kubelet-$NODE-csr.json;
    sed -i "s/\$NODE/$NODE/g" kubelet-$NODE-csr.json;
    cfssl gencert \
    -ca=${PKI_DIR}/ca.pem \
    -ca-key=${PKI_DIR}/ca-key.pem \
    -config=ca-config.json \
    -hostname=$NODE \
    -profile=kubernetes \
    kubelet-$NODE-csr.json | cfssljson -bare ${PKI_DIR}/kubelet-$NODE;
    rm -f kubelet-$NODE-csr.json
done

echo "==> Create Service Account Key"
# Service Account Key
openssl genrsa -out ${PKI_DIR}/sa.key 2048
openssl rsa -in ${PKI_DIR}/sa.key -pubout -out ${PKI_DIR}/sa.pub

ENCRYPT_SECRET=$( head -c 32 /dev/urandom | base64 )
sed -ri "/secret:/s#(: ).+#\1${ENCRYPT_SECRET}#" encryption.yml
cp -a encryption.yml audit-policy.yml kubelet-conf.yml kube-proxy.conf ${K8S_DIR}