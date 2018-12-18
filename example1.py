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
    inv.SetHostVars(inv.AddHost(group, "192.168.122.11"), "hostname", "node03")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.12"), "hostname", "node04")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.13"), "hostname", "node05")

    # 增加Etcd节点信息
    group = inv.AddGroup("etcd")
    inv.AddHost(group, "192.168.122.21")
    inv.AddHost(group, "192.168.122.22")
    inv.AddHost(group, "192.168.122.23")

    # 增加SLB节点信息
    group = inv.AddGroup("slb")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.21"), "priority", 99)
    inv.SetHostVars(inv.AddHost(group, "192.168.122.21"), "interface", "ens3")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.21"), "state", "MASTER")

    inv.SetHostVars(inv.AddHost(group, "192.168.122.22"), "priority", 98)
    inv.SetHostVars(inv.AddHost(group, "192.168.122.22"), "interface", "ens3")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.22"), "state", "BACKUP")

    inv.SetHostVars(inv.AddHost(group, "192.168.122.23"), "priority", 97)
    inv.SetHostVars(inv.AddHost(group, "192.168.122.23"), "interface", "ens3")
    inv.SetHostVars(inv.AddHost(group, "192.168.122.23"), "state", "BACKUP")

    # 设置SLB组变量
    inv.SetGroupVars(
        group,
        {
            "username": "admin",
            "password": "admin"
        }
    )

    # 设置全局环境变量
    inv.SetGlobalVars({
        "ansible_ssh_user": "root",  # 配置远程账户
        "TimeZone": "Asia/Shanghai",
        "NodePortRange": "30000-32767",
        "Interface": "ens3",  # 网络组建依赖的网卡
        "DockerVersion": "18.06.1",  # 配置Docker版本，默认值：17.03.3
        "VIP": "192.168.122.5",  # 配置Kubernetes ApiServer VIP地址
        "Port": "8443",  # 配置Kubernetes ApiServer VIP地址
        "VIPMask": "24",  # 配置Kubernetes ApiServer VIP地址掩码，默认值：24
        # "KUBE_APISERVER": "https://192.168.122.5:6443", # 配置Kubernetes ApiServer 调用地址，默认值：https://VIP:Port
        # "ClusterIPCIDR": "10.244.0.0/16", # 默认值：10.244.0.0/16
        # "ServiceClusterIPCIDR": "10.96.0.0/12", # 默认值：10.96.0.0/12
        # "ServiceDNSIP": "10.96.0.10", # 默认值：10.96.0.10
        "Network": "flannel",  # 网络组件，可选值：calico、flannel，默认值：flannel
        "DNS": "kube-dns",  # 集群DNS类型，可选值：coredns、kube-dns，默认值：coredns
        "Dashboard": False,  # 是否安装 Dashboard
        "MetricsServer": False,  # 是否安装Metrics Server
        "HelmTiller": False,  # 是否安装 Helm
        "IngressNginx": False,  # 是否安装Ingress Nginx
        "registry": False,
        "WeaveScope": False,
        "Prometheus": False,
        "IngressVIP": "192.168.122.6"
    })

    inv.GetJson()