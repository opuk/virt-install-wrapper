#!/bin/bash

../install.sh -n master1 -m 8192 -d 50 -e 15 | grep DONE
../install.sh -n master2 -m 8192 -d 50 -e 15 | grep DONE
../install.sh -n master3 -m 8192 -d 50 -e 15 | grep DONE
../install.sh -n infra1 -m 8192 -d 50 -e 15,250 | grep DONE
../install.sh -n infra2 -m 8192 -d 50 -e 15,250 | grep DONE
../install.sh -n infra3 -m 8192 -d 50 -e 15,250 | grep DONE
../install.sh -n infra4 -m 8192 -d 50 -e 15,250 | grep DONE
../install.sh -n node1 -m 4096 -d 50 -e 15 | grep DONE
../install.sh -n node2 -m 4096 -d 50 -e 15| grep DONE
../install.sh -n openshift -m 1024 | grep DONE

