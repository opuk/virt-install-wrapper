#!/bin/sh
for i in $(virsh list | grep [0-9] | awk '{print $2}');do virsh shutdown $i; done

