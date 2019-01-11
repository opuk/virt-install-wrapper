#!/bin/bash
virsh snapshot-delete --snapshotname clean master1
virsh snapshot-delete --snapshotname clean master2
virsh snapshot-delete --snapshotname clean master3
virsh snapshot-delete --snapshotname clean infra1
virsh snapshot-delete --snapshotname clean infra2
virsh snapshot-delete --snapshotname clean infra3
virsh snapshot-delete --snapshotname clean storage1
virsh snapshot-delete --snapshotname clean storage2
virsh snapshot-delete --snapshotname clean storage3
virsh snapshot-delete --snapshotname clean storage4
virsh snapshot-delete --snapshotname clean node1
virsh snapshot-delete --snapshotname clean node2
virsh snapshot-delete --snapshotname clean openshift
