#!/bin/bash
virsh snapshot-create-as --name clean master1
virsh snapshot-create-as --name clean master2
virsh snapshot-create-as --name clean master3
virsh snapshot-create-as --name clean infra1
virsh snapshot-create-as --name clean infra2
virsh snapshot-create-as --name clean infra3
virsh snapshot-create-as --name clean storage1
virsh snapshot-create-as --name clean storage2
virsh snapshot-create-as --name clean storage3
virsh snapshot-create-as --name clean storage4
virsh snapshot-create-as --name clean node1
virsh snapshot-create-as --name clean node2
virsh snapshot-create-as --name clean openshift
