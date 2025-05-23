#!/bin/bash

UUID=$(blkid /dev/nbd0p1 | grep -Eo ' UUID="[^ ]*"' | sed 's/[" ]//g')
echo "$UUID / ext4 errors=remount-ro 0 1" > /etc/fstab
