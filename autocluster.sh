#!/bin/bash

if [ -z "$ARCH" ]; then echo "ARCH is undefined, aborting."; exit 1; fi

if [ ! -f ubuntu-16.04-server-cloudimg-$ARCH-uefi1.img ]; then
  wget https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-$ARCH-uefi1.img  
fi

cp ubuntu-16.04-server-cloudimg-$ARCH-uefi1.img base.img

qemu-img resize base.img +16G

BASENAME=ubuntu-$(date | md5sum | cut -c1-8)
NODE_COUNT=12

for i in $(seq -w 01 $NODE_COUNT)
do
  cp base.img $BASENAME-$i.img
  sudo virt-sysprep -a $BASENAME-$i.img --hostname $BASENAME-$i --root-password password:ubuntu --ssh-inject root:file:/home/ubuntu/.ssh/id_rsa.pub &
done

until ! ps aux | grep -v grep | grep virt-sysprep > /dev/null; do sleep 1; done

for i in $(seq -w 01 $NODE_COUNT)
do
  sudo virt-install --name $BASENAME-$i --ram 4096 --disk path=$BASENAME-$i.img --vcpus 4 --import --graphics none --noautoconsole --network bridge=virbr0 &
done

for i in $(seq -w 01 $NODE_COUNT)
do
  until virsh net-dhcp-leases default | grep $BASENAME-$i; do echo waiting for $BASENAME-$i `date +%r`; sleep 1; done
  ACIP=$(virsh net-dhcp-leases default | grep $BASENAME-$i | awk '{print $5}' | cut -d "/" -f 1)
  ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $ACIP
  until ssh -o StrictHostKeyChecking=no root@$ACIP "echo `cat /home/ubuntu/.ssh/id_rsa.pub` >> /home/ubuntu/.ssh/authorized_keys"; do echo waiting for $BASENAME-$i ssh `date +%r`; sleep 1; done
done

ACIP=$(virsh net-dhcp-leases default | grep $BASENAME-01 | awk '{print $5}' | cut -d "/" -f 1)
juju bootstrap manual/$ACIP $BASENAME

for i in $(seq -w 02 $NODE_COUNT)
do
  ACIP=$(virsh net-dhcp-leases default | grep $BASENAME-$i | awk '{print $5}' | cut -d "/" -f 1)
  juju add-machine ssh:ubuntu@$ACIP &
done

until ! ps aux | grep -v grep | grep add-machine > /dev/null; do sleep 1; done
