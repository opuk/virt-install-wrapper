#!/bin/bash 


function print_help {
   echo "Required arg is -n (--name) for the vm name"
   echo "-m / --mem : Set memory for VM - Default 2GB"
   echo "-c / --cpu : Set CPU cores for VM - Default 2 vcpu"
   echo "-d / --primary-disk : Set the size of the OS disk - Default 40G"
   echo "-e / --extra-disk : Set number of extra disks via specific size - Default no extra disks"
   echo ""
   echo "Example:"
   echo "Create a vm called test-server with 4 cpu, 12GB ram, 40GB primary disk and with 3 extra disks with 10 GB each"
   echo "./install.sh -n test-server -m 12288 -c 4 -d 40G -e 10,10,10"
   echo ""
   echo "This will create a disk with sda (40G), sdb (10G), sdc (10G), and sdd (10G) "
}

NAME=""
MEM="2048"
CPU="2"
DISK_SIZE="40G"
EXTRA_DISKS=""

WORKDIR=/var/lib/libvirt/images
IMAGE=$WORKDIR/rhel-server-7.6-x86_64-kvm.qcow2

RUN_AFTER=1
RESIZE_DISK=1
DISK_SIZE="40G"
OS="rhel7.5"

ROOTPASS=redhat123

DOMAIN=example.com
PRIMARY_NETWORK=default

while [[ $# -ge 1 ]]; do
   key="$1"
   case $key in
      -n|--name)
          readonly NAME="$2"
          shift # past argument=value
      ;;
      -m|--mem)
          readonly MEM="$2"
          shift
      ;;
      -c|--cpu)
          readonly CPU="$2"
          shift
      ;;
      -d|--primary-disk)
          readonly DISK_SIZE="$2"
          shift
      ;;
      -e|--extra-disk)
          readonly EXTRA_DISKS="$2"
          shift
      ;;
      -h|--help)
          print_help
          exit 0
      ;;
      *)
          echo \"${key}\" is an invalid argument.
          print_help
          exit 1
      ;;
   esac
shift
done

if [[ -z $NAME ]]; then
  print_help
  exit 1
fi

pushd $WORKDIR

cp $IMAGE $NAME.qcow2

# Resize the disk to requested size
if [[ "${RESIZE_DISK}" -eq "1" ]]; then
  echo "$(date -R) Resizing the disk..."
  virt-filesystems --long -h --all -a $NAME.qcow2
  qemu-img resize $NAME.qcow2 $DISK_SIZE
  cp $NAME.qcow2 $NAME.qcow2.new
  virt-resize --expand /dev/sda1 $NAME.qcow2 $NAME.qcow2.new
  mv $NAME.qcow2.new $NAME.qcow2
fi

virt-customize -a $NAME.qcow2 \
  --hostname $NAME.$DOMAIN \
  --root-password password:$ROOTPASS \
  --uninstall cloud-init \
  --timezone "$TIMEZONE" \
  --selinux-relabel


echo "$(date -R) Power off the vm to finish installation."

function _create_extra_disks_args {
        local i=1
        local disk_args=''
        for disk in $(echo $EXTRA_DISKS | xargs -d ','); do
                local disk_args="${disk_args} --disk ${NAME}-extra-${i}.qcow2,format=qcow2,size=${disk}"
                local i=$(($i+1))
        done
        echo $disk_args
}

disk_args=$(_create_extra_disks_args ${EXTRA_DISKS})

virt-install --noautoconsole --noreboot \
      --name $NAME \
      --ram $MEM \
      --vcpus $CPU \
      --import \
      --disk $NAME.qcow2,format=qcow2,bus=virtio \
      --network network:$PRIMARY_NETWORK \
      --os-variant $OS \
      $disk_args



if [[ ${RUN_AFTER} -eq "1" ]]; then
  echo "$(date -R) Launching the $NAME domain..."

  virsh start $NAME

  mac=`virsh dumpxml $NAME | grep "mac address" | tr -s \' ' '  | awk ' { print $3 } '`

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
