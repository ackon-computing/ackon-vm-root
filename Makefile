
create_root:
	debootstrap --include=docker.io,cryptsetup bookworm target
	rsync -vah etc/* target/etc
	chroot target apt-get update
	chroot target apt-get install -y linux-image-amd64
	chroot target apt-get install -y grub-pc
	chroot target apt-get install -y python3
	chroot target apt-get install -y openssl
	chroot target apt-get install -y qemu-guest-agent
	chroot target bash -c 'echo "root:root" | chpasswd'

create_qcow2:
	qemu-img create -f qcow2 ackon-runner.img 20G
	modprobe nbd max_part=8
	qemu-nbd --connect=/dev/nbd0 ackon-runner.img
	sleep 15
	fdisk /dev/nbd0 -l
	parted /dev/nbd0 mklabel msdos --script
	parted /dev/nbd0 mkpart primary 0% 50% --script
	parted /dev/nbd0 mkpart primary 50% 100% --script
	fdisk /dev/nbd0 -l
	sleep 10
	partprobe
	sleep 10
	mkfs.ext4 /dev/nbd0p1
	mkfs.ext4 /dev/nbd0p2
	sleep 10
	mkdir -p target-mount
	mount /dev/nbd0p1 target-mount
	mv target/* target-mount/
	$(MAKE) create_qcow2_grub

create_qcow2_grub:
	mount --bind /dev ./target-mount/dev
	mount -t devpts /dev/pts ./target-mount/dev/pts
	mount -t proc proc ./target-mount/proc
	mount -t sysfs sysfs ./target-mount/sys
	mount -t tmpfs tmpfs ./target-mount/tmp
	chroot target-mount bash -c "echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub"
	chroot target-mount grub-install --target=i386-pc --recheck /dev/nbd0
	chroot target-mount update-grub2

#bash -c "UUID1=$(blkid /dev/nbd0p2 | grep -Eo ' UUID="[^ ]*"' | sed 's/[" ]//g'); "
#echo "$UUID1 / ext4 errors=remount-ro 0 1" >> /etc/fstab


clean:
	rm -rf target

deps:
	apt-get install apt-get install qemu-block-extra qemu-utils debootstrap rsync
