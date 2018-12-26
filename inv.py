#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import inventory

if __name__ == "__main__":
    inv = inventory.hosts()
    # 增加Master节点信息
    group = inv.AddGroup("master")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.21"), "hostname", "master01")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.22"), "hostname", "master02")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.23"), "hostname", "master03")

    # 增加Node节点信息
    group = inv.AddGroup("node")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.31"), "hostname", "node01")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.32"), "hostname", "node02")

    # 增加Etcd节点信息
    group = inv.AddGroup("etcd")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.11"), "hostname", "etcd01")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.12"), "hostname", "etcd02")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.13"), "hostname", "etcd03")
    # inv.SetHostVars(inv.AddHost(group, "192.168.122.10"), "hostname", "etcd04")

    # 增加SLB节点信息
    group = inv.AddGroup("slb")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.8"), "hostname", "slb01")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.8"), "priority", 99)
    inv.SetHostVars(inv.AddHost(group, "192.168.122.8"), "interface", "ens3")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.8"), "state", "MASTER")

    inv.SetHostVars(inv.AddHost(group, "192.168.122.9"), "hostname", "slb02")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.9"), "priority", 98)
    inv.SetHostVars(inv.AddHost(group, "192.168.122.9"), "interface", "ens3")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.9"), "state", "BACKUP")

    # 设置SLB组变量
    inv.SetGroupVars(
        group,
        {
            "username": "admin",
            "password": "admin",
            "slb": "nginx"
        }
    )

    # 设置全局环境变量
    inv.SetGlobalVars({
        "ansible_ssh_user": "root", # 配置远程账户
        "TimeZone": "Asia/Shanghai", # 设置系统时区，默认值：Asia/Shanghai
        "NodePortRange": "30000-32767", # 设置集群NodePort端口，默认值：30000-32767
        "DockerVersion": "18.06.1", # 配置Docker版本，默认值：17.03.3
        "VIP": "192.168.122.5", # 配置Kubernetes ApiServer VIP地址，默认值：N/A（必填项）
        # "Port": "6443", # 配置Kubernetes ApiServer VIP端口，默认值：6443，若Haporxy在Master节点，请设置为8443，防止端口冲突
        "VIPMask": "16", # 配置Kubernetes ApiServer VIP地址掩码，默认值：24
        # "KUBE_APISERVER": "https://192.168.122.5:6443", # 配置Kubernetes ApiServer 调用地址，默认值：https://VIP:Port
        "ClusterIPCIDR": "10.244.0.0/16", # 默认值：10.244.0.0/16
        "ServiceClusterIPCIDR": "10.96.0.0/12", # 默认值：10.96.0.0/12
        "ServiceDNSIP": "10.96.0.10", # 默认值：10.96.0.10
        "Network": "flannel", # 网络组件，可选值：calico、flannel，默认值：flannel
        "Interface": "ens3",  # 网络组建依赖的网卡
        "DNS": "coredns",  # 集群DNS类型，可选值：coredns、kube-dns，默认值：coredns
        "Dashboard": False, # 是否安装 Dashboard，默认值：False
        "MetricsServer": True, # 是否安装Metrics Server，默认值：False
        "HelmTiller": False, # 是否安装 Helm，默认值：False
        "Registry": False, # 是否安装Registry，默认值：False
        "WeaveScope": False, # 是否安装WeaveScope，默认值：False
        "Prometheus": False, # 是否安装Prometheus，默认值：False
        "EFK": False, # 是否安装Prometheus，默认值：False
        "IngressController": "traefik", # IngressController插件，可选值：nginx、traefik，默认值：traefik
        "IngressControllerNginxVIP": "192.168.122.6", # Ingress Nginx使用的VIP，若IngressNginx参数为True，需要设置该变量值
        "NFS": False, # 是否集成NFS，该功能不安装NFS，请自行安装
        "NFS_SERVER": "192.168.122.3" # NFS服务器地址，若NFS参数为True，需要设置该变量值
    })

    inv.GetJson()