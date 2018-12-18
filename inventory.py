#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import json, sys


class hosts:
    def __init__(self):
        self.host = {}

    def AddGroup(self, group):
        if group not in self.host:
            self.host[group] = {}
        return group

    def SetGroupVars(self, group, dic):
        if group not in self.host:
            self.host[group] = {}
            self.host[group]['vars'] = {}
        self.host[group]['vars'] = dic

    def AddHost(self, group, ip):
        if 'hosts' not in self.host[group]:
            self.host[group]['hosts'] = []
        self.host[group]['hosts'].append(ip)
        self.host[group]['hosts'] = list(set(set(self.host[group]['hosts'])))
        return ip

    def SetHostVars(self, ip, key, value):
        if '_meta' not in self.host:
            self.host['_meta'] = {}
            self.host['_meta']['hostvars'] = {}
        if ip not in self.host['_meta']['hostvars']:
            self.host['_meta']['hostvars'][ip] = {}
        self.host['_meta']['hostvars'][ip][key] = value

    def SetGlobalVars(self, dic):
        if 'all' not in self.host:
            self.host['all'] = {}
            self.host['all']['vars'] = {}

        if 'Dashboard' not in dic:
            dic['Dashboard'] = False

        if 'MetricsServer' not in dic:
            dic['MetricsServer'] = False

        if 'HelmTiller' not in dic:
            dic['HelmTiller'] = False

        if 'Registry' not in dic:
            dic['Registry'] = False

        if 'WeaveScope' not in dic:
            dic['WeaveScope'] = False

        if 'Prometheus' not in dic:
            dic['Prometheus'] = False

        if 'IngressController' not in dic:
            dic['IngressController'] = "traefik"
        else:
            if dic['IngressController'] == "traefik":
                if 'IngressControllerNginxVIP' not in dic:
                    print("You IngressController type is Nginx, please set IngressControllerNginxVIP variable")
                    sys.exit(1)

        if 'NFS' not in dic:
            dic['NFS'] = False
        else:
            if 'NFS_SERVER' not in dic:
                print("You have enabled NFS, please set NFS_SERVER variable")
                sys.exit(1)

        if 'Port' not in dic:
            if cmp(self.host['slb']['hosts'],self.host['master']['hosts']):
                dic['Port'] = "6443"
            else:
                dic['Port'] = "8443"

        if 'KUBE_APISERVER' not in dic:
            dic['KUBE_APISERVER'] = "https://%s:%s" % (dic['VIP'], dic['Port'])

        if 'ClusterIPCIDR' not in dic:
            dic['ClusterIPCIDR'] = "10.244.0.0/16"

        if 'ServiceClusterIPCIDR' not in dic:
            dic['ServiceClusterIPCIDR'] = "10.96.0.0/12"

        if 'ServiceDNSIP' not in dic:
            dic['ServiceDNSIP'] = "10.96.0.10"

        if 'DNS' not in dic:
            dic['DNS'] = "coredns"

        if 'Network' not in dic:
            dic['Network'] = "flannel"

        if 'DockerVersion' not in dic:
            dic['DockerVersion'] = "17.03.3"

        if 'VIPMask' not in dic:
            dic['VIPMask'] = "24"

        if 'TimeZone' not in dic:
            dic['TimeZone'] = "Asia/Shanghai"

        if 'NodePortRange' not in dic:
            dic['NodePortRange'] = "30000-32767"

        self.host['all']['vars'] = dic

    def AddChildren(self, group, groupnamelist):
        if group not in self.host:
            self.host[group] = {}
            self.host[group]['children'] = []
        self.host[group]['children'] = groupnamelist

    def GetJson(self):
        if 'master' not in self.host:
            print("master group not in inventory")
            return
        if 'node' not in self.host:
            print("node group not in inventory")
            return
        if 'slb' not in self.host:
            print("slb group not in inventory")
            return
        if 'etcd' not in self.host:
            print("etcd group not in inventory")
            return
        self.AddChildren("kubernetes", ['master', 'node'])
        print(json.dumps(self.host, indent=4))