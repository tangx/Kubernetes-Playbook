apt-get install nfs-kernel-server -y
echo "/mnt/kubernetes 192.168.122.*(rw,sync,insecure,no_subtree_check,no_root_squash)" > /etc/exports
systemctl restart nfs-kernel-server.service
systemctl enable nfs-kernel-server.service


sudo virt-clone -o Ubuntu16.04 -n nfs -f /data/kvm/disk/nfs.qcow2
sudo qemu-img create -f raw /data/kvm/disk/nfs.data.img 50G
sudo virsh start nfs
sudo virsh attach-disk nfs /data/kvm/disk/nfs.data.img vdb --cache none
sudo virsh detach-disk nfs vdb