#!/bin/bash

../install.sh master1 8192 | grep DONE
../install.sh master2 8192 | grep DONE
../install.sh master3 8192 | grep DONE
../install.sh infra1 8192 | grep DONE
../install.sh infra2 8192 | grep DONE
../install.sh infra3 8192 | grep DONE
../install.sh infra4 8192 | grep DONE
../install.sh node1 4096 | grep DONE
../install.sh node2 2048 | grep DONE
../install.sh openshift 1024 | grep DONE
