#!/bin/bash 

NAME=$1
MEM=$2
CPU=2

WORKDIR=/var/lib/libvirt/images
#IMAGE=$WORKDIR/Fedora-Cloud-Base-25-1.3.x86_64.qcow2
#IMAGE=$WORKDIR/CentOS-7-x86_64-GenericCloud.qcow2
IMAGE=$WORKDIR/rhel-server-7.6-x86_64-kvm.qcow2
ROOTPASS=redhat123
TIMEZONE="Europe/Stockholm"

RUN_AFTER=false
DISK_SIZE=40G
EXTRA_DISK_SIZE=20
#Comment out this line if you don't need a extra disk
#SECONDARY_DISK="--disk path=${WORKDIR}/$NAME-extra.qcow2,device=disk,bus=virtio,format=qcow2,size=$EXTRA_DISK_SIZE"

NETWORK_PRIMARY=provisioning
DOMAIN=lab.moogle.cloud

#OSP networks
PROV_NET=$NETWORK_PRIMARY
TRUNK_NET=trunk
PUBLIC_NET=public

NETWORKS="--network network:$PROV_NET --network network:$TRUNK_NET --network network:$TRUNK_NET --network network:$PUBLIC_NET"

pushd $WORKDIR

qemu-img create -f qcow2 $NAME.qcow2 $DISK_SIZE

virt-resize --expand /dev/sda1 ${IMAGE} $NAME.qcow2
virt-customize -a $NAME.qcow2 \
  --hostname $NAME.$DOMAIN \
  --root-password password:$ROOTPASS \
  --uninstall cloud-init \
  --timezone "$TIMEZONE" \
  --selinux-relabel
  
virt-install --ram $MEM --vcpus $CPU --os-variant rhel7 \
   --disk path=${WORKDIR}/$NAME.qcow2,device=disk,bus=virtio,format=qcow2 \
   --import --noautoconsole --vnc $NETWORKS \
   --name $NAME --cpu host,+vmx $SECONDARY_DISK 

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

  echo "$(date -R) DONE, ssh to $ip to access $NAME"
fi


