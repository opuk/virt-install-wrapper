#!/bin/bash
virsh shutdown master1
virsh shutdown master2
virsh shutdown master3
virsh shutdown infra1
virsh shutdown infra2
virsh shutdown infra3
virsh shutdown infra4
virsh shutdown node1
virsh shutdown node2
virsh shutdown openshift
