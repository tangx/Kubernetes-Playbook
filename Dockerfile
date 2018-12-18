FROM ubuntu:16.04

COPY sources.list /etc/apt/sources.list

# 安装ansible
RUN apt-get update \
    && apt-get install --no-install-recommends wget software-properties-common vim jq -y \
    && apt-add-repository ppa:ansible/ansible \
    && apt-get update \
    && apt-get install ansible -y \
    && sed -i "s/#host_key_checking.*/host_key_checking = False/g" /etc/ansible/ansible.cfg \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

# 下载cfssl、cfssljson
RUN wget "https://pkg.cfssl.org/R1.2/cfssl_linux-amd64" -O /usr/local/bin/cfssl \
    && wget "https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64" -O /usr/local/bin/cfssljson \
    && chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

# 下载Etcd二进制文件
ENV ETCD_VERSION=v3.3.9
RUN wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -O /usr/local/src/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
    && tar -zxvf /usr/local/src/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
        --strip-components=1 -C /usr/local/bin \
        etcd-${ETCD_VERSION}-linux-amd64/etcd \
        etcd-${ETCD_VERSION}-linux-amd64/etcdctl \
    && rm -rf /usr/local/src/etcd-${ETCD_VERSION}-linux-amd64.tar.gz

# 下载CNI二进制文件
ENV CNI_VERSION=v0.7.1
RUN wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz" -O /usr/local/src/cni-plugins-amd64-${CNI_VERSION}.tgz \
    && mkdir -p /opt/cni/bin \
    && tar -zxf /usr/local/src/cni-plugins-amd64-${CNI_VERSION}.tgz -C /opt/cni/bin \
    && rm -rf /usr/local/src/cni-plugins-amd64-${CNI_VERSION}.tgz

# 下载HELM二进制文件
ENV HELM_VERSION=v2.11.0
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O /usr/local/src/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxvf /usr/local/src/helm-${HELM_VERSION}-linux-amd64.tar.gz  \
        --strip-components=1 -C /usr/local/bin \
        linux-amd64/helm \
    && rm -rf /usr/local/src/helm-${HELM_VERSION}-linux-amd64.tar.gz

# 下载Kubernetes二进制文件
ENV KUBE_VERSION=v1.13.0
RUN wget https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/kubernetes-server-linux-amd64.tar.gz -O /usr/local/src/kubernetes-server-linux-amd64.tar.gz \
    && tar -zxvf /usr/local/src/kubernetes-server-linux-amd64.tar.gz  \
        --strip-components=3 -C /usr/local/bin \
        kubernetes/server/bin/kubelet \
        kubernetes/server/bin/kubectl \
        kubernetes/server/bin/kube-apiserver \
        kubernetes/server/bin/kube-controller-manager \
        kubernetes/server/bin/kube-scheduler \
        kubernetes/server/bin/kube-proxy \
    && rm -rf /usr/local/src/kubernetes-server-linux-amd64.tar.gz

# 拷贝项目
COPY . /playbook

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

WORKDIR /playbook

VOLUME ["/etc/kubernetes", "/etc/etcd/ssl"]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "ansible-playbook", "-i", "inv.py", "deploy.yaml" ]