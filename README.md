# Kubernetes-Playbook

## 简介

比较懒，不想写。

## 系统支持

* [x] Ubuntu 16.04

* [ ] CentOS 7.*

## 节点资源

| 角色 | CPU | 内存 | 数量 |
| --- | --- | --- | --- |
| SLB | 1C | 1G | >=2 |
| Etcd | 1C | 1G | 2n+1 |
| Master | 1C | 2G | >=2 |
| Node | 1C | 1G | >=1 |

## 云服务商

* [x] QingCloud

* [ ] AliYun

## 各组件版本

可修改 `Dockerfile` 对应组件版本自行构建。

| 组件 | 版本 |
| --- | --- |
| CNI | 0.7.1 |
| Etcd | 3.3.9 |
| Kubernetes | 1.10+ |


## 使用
### 1. 前提条件

1. slb主机系统版本保持一致 

2. kubernetes主机系统保持一致，要么Ubuntu要么CentOS，不支持混搭

3. 请不要在集群节点运行本容器，因为中途会重启docker组件导致部署中断

### 2. 设置资产信息

请参考本项目 `inv.py` 文件配置

### 3. 部署集群

```
docker pull daocloud.io/buxiaomo/k8splaybook:v1.13.0
docker run -it --rm --name k8splaybook \
-v kubernetes:/etc/kubernetes:rw \
-v etcd:/etc/etcd/ssl:rw \
-v /root/.ssh/id_rsa:/root/.ssh/id_rsa \
-v /root/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
-v /root/inv.py:/playbook/inv.py \
daocloud.io/buxiaomo/k8splaybook:v1.13.0
```

<!-- ## 设置主机静态IP

```
docker run -it --rm \
-v /Users/momo/.ssh/id_rsa:/root/.ssh/id_rsa \
-v /Users/momo/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
daocloud.io/buxiaomo/k8splaybook:v1.11.3
```

```
auto ens3
iface ens3 inet static
address 10.100.12.65
netmask 255.255.255.0
gateway 10.100.12.254
dns-nameserver 114.114.114.114

nmcli connection add \
ifname eth0 \
con-name static \
type ethernet autoconnect yes \
ipv4.method manual \
ipv4.addresses '192.168.122.7/24' \
ipv4.gateway 192.168.122.1 ipv4.dns 114.114.114.114
``` -->

## 升级内核

CentOS 系统请升级系统内核后在使用剧本部署。

```
export Kernel_Vsersion=4.4.0-2
wget  http://mirror.rc.usf.edu/compute_lock/elrepo/kernel/el7/x86_64/RPMS/kernel-ml{,-devel}-${Kernel_Vsersion}.el7.elrepo.x86_64.rpm
yum localinstall -y kernel-ml*
grub2-set-default  0 && grub2-mkconfig -o /etc/grub2.cfg
```
## 检查Etcd集群状态

部署完成后会给出检查命令

```
etcdctl --endpoints "https://10.0.100.11:2379,https://10.0.100.12:2379,https://10.0.100.13:2379" \
--ca-file=/etc/etcd/ssl/etcd-ca.pem \
--cert-file=/etc/etcd/ssl/etcd.pem  \
--key-file=/etc/etcd/ssl/etcd-key.pem cluster-health
```

## Kubernetes Dashboard Token

```
kubectl -n kube-system describe secrets | sed -rn '/\sdashboard-token-/,/^token/{/^token/s#\S+\s+##p}'
```

## 检查各服务状态

```
systemctl status kubelet kube-apiserver kube-controller-manager kube-scheduler kube-proxy
```

## 检查各服务日志输出

```
journalctl -fu kubelet
journalctl -fu kube-apiserver
journalctl -fu kube-controller-manager
journalctl -fu kube-scheduler
journalctl -fu kube-proxy
```

## 主机污点

```
# 增加
kubectl taint node master01 node-role.kubernetes.io/master="":NoSchedule
kubectl taint node master02 node-role.kubernetes.io/master="":NoSchedule
kubectl taint node master03 node-role.kubernetes.io/master="":NoSchedule

# 去除
kubectl taint node master01 node-role.kubernetes.io/master:NoSchedule-
kubectl taint node master02 node-role.kubernetes.io/master:NoSchedule-
kubectl taint node master03 node-role.kubernetes.io/master:NoSchedule-
```