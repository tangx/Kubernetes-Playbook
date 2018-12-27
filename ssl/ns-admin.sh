# 允许某用户对同名NameSpace拥有所有权限
# 创建admin、dev、ops用户权限

USER=$1
mkdir -p /etc/kubernetes/pki/user/${USER}
cd /etc/kubernetes/pki/user/${USER}
cat > ${USER}.json << EOF
{
    "CN": "${USER}",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "Hangzhou",
        "L": "Hangzhou",
        "O": "Kubernetes",
        "OU": "System"
      }
    ]
  }
EOF

cfssl gencert --ca /etc/kubernetes/pki/ca.pem \
--ca-key /etc/kubernetes/pki/ca-key.pem \
--config /playbook/ssl/ca-config.json \
--profile kubernetes ${USER}.json | \
cfssljson --bare ${USER}

export KUBE_APISERVER=$(python /playbook/inv.py | jq -r .all.vars.KUBE_APISERVER)
kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${USER}.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials ${USER} \
--client-certificate=${USER}.pem \
--client-key=${USER}-key.pem \
--embed-certs=true \
--kubeconfig=${USER}.kubeconfig

# 设置上下文参数
kubectl config set-context kubernetes \
--cluster=kubernetes \
--user=${USER} \
--namespace=${USER} \
--kubeconfig=${USER}.kubeconfig

# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=${USER}.kubeconfig

cp -f /etc/kubernetes/admin.kubeconfig /root/.kube/config
kubectl create ns ${USER}
kubectl create rolebinding ${USER}-admin-binding --clusterrole=admin --user=${USER} --namespace=${USER}

cp -f /etc/kubernetes/pki/user/${USER}/${USER}.kubeconfig /root/.kube/config