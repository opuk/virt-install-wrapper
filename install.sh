#!/bin/bash

NAME=$1
MEM=$2
CPU=2

WORKDIR=/var/lib/libvirt/images
#IMAGE=$WORKDIR/Fedora-Cloud-Base-25-1.3.x86_64.qcow2
IMAGE=$WORKDIR/CentOS-7-x86_64-GenericCloud.qcow2
#IMAGE=$WORKDIR/rhel-guest-image-7.3-35.x86_64.qcow2

RUN_AFTER=true
RESIZE_DISK=true
DISK_SIZE=20G

pushd $WORKDIR

cp $IMAGE $NAME.qcow2
echo "$(date -R) Power off the vm to finish installation."
virt-install --import --name $NAME --ram $MEM --vcpus $CPU --disk $NAME.qcow2,format=qcow2,bus=virtio --network bridge=virbr0,model=virtio --os-type=linux

if $RESIZE_DISK; then
  echo "$(date -R) Resizing the disk..."
  virt-filesystems --long -h --all -a $NAME.qcow2
  qemu-img create -f qcow2 -o preallocation=metadata $NAME.qcow2.new $DISK_SIZE 
  virt-resize --quiet --expand /dev/sda1 $NAME.qcow2 $NAME.qcow2.new 
  mv $NAME.qcow2.new $NAME.qcow2
fi

if $RUN_AFTER; then
  echo "$(date -R) Launching the $1 domain..."

  virsh start $1

  mac=`virsh dumpxml $1 | grep "mac address" | tr -s \' ' '  | awk ' { print $3 } '`

  while true; do
    ip=`arp -na | grep $mac | awk '{ print $2 }' | tr -d \( | tr -d \)`

    if [ "$ip" = "" ]; then
      sleep 1
    else
      break
    fi
  done

  echo "$(date -R) DONE, ssh to the $ip host using 'fedora' or 'cloud-user' username and password 'fedora'"
fi

