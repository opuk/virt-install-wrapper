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

CINITDIR=/data/cloud-init
WORKDIR=/var/lib/libvirt/images
ISODIR=/data/isos
IMAGE=$ISODIR/rhel-server-7.4-x86_64-kvm.qcow2

RUN_AFTER=1
RESIZE_DISK=1
DISK_SIZE="40G"
OS="rhel7.5"

DOMAIN=vms.lab.be

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


function get_free_ip {
    function check_arp {
        local _ip=${1}
        local arp_result=$(arp -na | grep "${_ip}")

        if [[ -z "${arp_result}" ]]; then
            return 0
        fi
        return 1
    }

    function check_file {
        local _ip=${1}
        local _dbfile='/data/.vm_ip.db'
        local file_res=$(grep "${_ip}" "${_dbfile}")

        if [[ -z "${file_res}" ]]; then
            return 0
        fi
        return 1
    }

    while [[ -z "${free_ip}" ]]; do
        local _suffix=$(shuf -i 100-200 -n 1)
        local _ip="10.0.0.${_suffix}"

        check_file $_ip

        if [[ "$?" -eq 0 ]]; then
            check_arp ${_ip}

            if [[ "$?" -eq 0 ]]; then
               local free_ip="$_ip"
            fi
        fi
    done
    echo "${free_ip}:${NAME}" >> /data/.vm_ip.db
    echo $free_ip
}
# Function to update unbound local-data
function dns_update {
    local ip=$1
    local hostname=$2
    echo "   local-data: \"${hostname} A ${ip}\"" >> /etc/unbound/local.d/vms.lab.be.conf
    echo "   local-data-ptr: \"${ip} ${hostname}\"" >> /etc/unbound/local.d/vms.lab.be.conf
    systemctl restart unbound
}

# Fix a iso for cloud-init data

mkdir ${CINITDIR}/${NAME}
pushd $CINITDIR/${NAME}

assigned_ip=$(get_free_ip)
dns_update "$assigned_ip" "$NAME.$DOMAIN"
echo "will get ip $assigned_ip"


cat << EOF > meta-data
instance-id: lab-host-${NAME}
local-hostname: ${NAME}.${DOMAIN}
network-interfaces: |
  iface eth0 inet static
  address ${assigned_ip}
  network 10.0.0.0
  netmask 255.255.255.0
  broadcast 10.0.0.255
  gateway 10.0.0.1
bootcmd:
  - ifdown eth0
  - ifup eth0
EOF

cat << EOF > user-data
#cloud-config
cloud_config_modules: 
  - resolv_conf
ssh_authorized_keys:
  - ssh-rsa SSH_PUB_KEY
manage_resolv_conf: true
resolv_conf:
    nameservers: ['10.0.0.1']
    searchdomains:
        - vms.lab.be
    domain: vms.lab.be
    options:
        timeout: 1
EOF

# Create the ISO for cloud-init
genisoimage -output cloud-init-${NAME}.iso -volid cidata -joliet -rock user-data meta-data

# Leave cloud-init folder.
popd
# Work on cloning rhel imaage and starting vm
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

echo "$(date -R) Power off the vm to finish installation."

echo "${CINITDIR}/${NAME}/cloud-init-${NAME}.iso"

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
      --disk $NAME.qcow2,format=qcow2,bus=virtio \
      --network bridge=virbr0,model=virtio \
      --disk path=${CINITDIR}/${NAME}/cloud-init-${NAME}.iso,device=cdrom \
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

  echo "$(date -R) DONE, ssh to $ip or ${NAME}.vms.lab.be to access $NAME"
fi
