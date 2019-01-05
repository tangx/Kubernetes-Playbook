apt-get install nfs-kernel-server -y
echo "/mnt/kubernetes 192.168.122.*(rw,sync,insecure,no_subtree_check,no_root_squash)" > /etc/exports
echo "/dev/vdb /mnt/kubernetes xfs defaults 0 0" >> /etc/fstab
systemctl restart nfs-kernel-server.service
systemctl enable nfs-kernel-server.service

# sudo qemu-img create -f raw /data/kvm/disk/nfs.data.img 50G
# sudo virsh start nfs
# sudo virsh attach-disk nfs /data/kvm/disk/nfs.data.img vdb --cache none
# sudo virsh detach-disk nfs vdb