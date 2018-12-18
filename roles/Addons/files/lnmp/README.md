# 部署LNMP
```shell
kubectl create -f configmap.yml -f mysql.yml -f nginx.yml  -f php.yml
```
访问链接：http://$HOSTIP:30001

# 删除服务
```shell
kubectl delete -f configmap.yml -f mysql.yml -f nginx.yml  -f php.yml
```

# 横向扩展
```shell
# Nginx
kubectl scale deployment --replicas=2 lnmp-nginx

# PHP
kubectl scale deployment --replicas=2 lnmp-php
```