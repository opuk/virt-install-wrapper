#!/bin/bash

cat > /tmp/provisioning.xml <<EOF
<network>
  <name>provisioning</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address="192.168.0.1" netmask="255.255.255.0"/>
</network>
EOF

cat > /tmp/trunk.xml <<EOF
<network>
  <name>trunk</name>
  <ip address="172.16.0.1" netmask="255.255.255.0"/>
</network>
EOF

cat > /tmp/public.xml <<EOF
<network>
  <name>public</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <ip address="10.10.10.1" netmask="255.255.255.0"/>
</network>
EOF

for NETWORK in provisioning public trunk
do
  virsh net-define /tmp/${NETWORK}.xml
  virsh net-autostart ${NETWORK}
  virsh net-start ${NETWORK}
done

rm -f /tmp/provisioning.xml
rm -f /tmp/trunk.xml
rm -f /tmp/public.xml
