#!/bin/bash

virsh destroy master1
virsh destroy master2
virsh destroy master3
virsh destroy infra1
virsh destroy infra2
virsh destroy infra3
virsh destroy infra4
virsh destroy node1
virsh destroy node2
virsh destroy openshift

virsh undefine master1 --remove-all-storage
virsh undefine master2 --remove-all-storage
virsh undefine master3 --remove-all-storage
virsh undefine infra1 --remove-all-storage
virsh undefine infra2 --remove-all-storage
virsh undefine infra3 --remove-all-storage
virsh undefine infra4 --remove-all-storage
virsh undefine node1 --remove-all-storage
virsh undefine node2 --remove-all-storage
#virsh destroy openshift --remove-all-storage

