#!/bin/bash
virsh destroy master1
virsh destroy master2
virsh destroy master3
virsh destroy infra1
virsh destroy infra2
virsh destroy infra3
virsh destroy storage1
virsh destroy storage2
virsh destroy storage3
virsh destroy storage4
virsh destroy node1
virsh destroy node2
virsh destroy openshift
