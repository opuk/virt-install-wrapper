#!/bin/bash
virsh snapshot-revert --snapshotname clean master1
virsh snapshot-revert --snapshotname clean master2
virsh snapshot-revert --snapshotname clean master3
virsh snapshot-revert --snapshotname clean infra1
virsh snapshot-revert --snapshotname clean infra2
virsh snapshot-revert --snapshotname clean infra3
virsh snapshot-revert --snapshotname clean storage1
virsh snapshot-revert --snapshotname clean storage2
virsh snapshot-revert --snapshotname clean storage3
virsh snapshot-revert --snapshotname clean storage4
virsh snapshot-revert --snapshotname clean node1
virsh snapshot-revert --snapshotname clean node2
virsh snapshot-revert --snapshotname clean openshift
