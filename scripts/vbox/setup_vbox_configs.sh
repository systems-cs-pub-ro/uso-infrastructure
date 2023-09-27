#!/bin/bash

# This script is used to setup the virtualbox configurations for the VMs

vboxmanage modifyvm "test" --name "USO"

vboxmanage modifyvm "USO" --audio pulse --audiocontroller hda --audioout on \
    --boot1 dvd --boot2 disk --pae off --usb on --vram 16 \
    --graphicscontroller vmsvga --vrde off --nic1 nat --nictype1 82540EM \
    --nic2 hostonly --nictype2 82540EM --hostonlyadapter2 vboxnet0 \
    --memory 2048 --cpus 2

