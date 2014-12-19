#!/bin/bash
targetdir='rootfs'
set -x

sudo apt-get install -y qemu-user-static debootstrap binfmt-support

mkdir $targetdir

# debootstarp
sudo qemu-debootstrap --arch=mipsel  testing $targetdir http://mirrors.ustc.edu.cn/debian/
sudo cp /usr/bin/qemu-mipsel-static $targetdir/usr/bin/

# before chroot
sudo cp /etc/resolv.conf $targetdir/etc
sudo mount devpts $targetdir/dev/pts -t devpts
sudo mount -t proc proc $targetdir/proc
# source.list
echo "deb http://mirrors.ustc.edu.cn/debian testing main non-free contrib" > sources.list
echo "deb [trusted=yes] http://packages.linuxdeepin.com/loongson testing main" >> sources.list
sudo cp sources.list $targetdir/etc/apt/
# gpg key
sudo cp mipsel.gpg.key $targetdir/
# deepin first
echo "Package: *" > testing
echo "Pin: origin packages.linuxdeepin.com" >> testing
echo "Pin-Priority: 600" >> testing
sudo cp testing $targetdir/etc/apt/preferences.d/

# chroot install script
sudo touch ins.sh
sudo chmod 777 ins.sh
sudo echo "cat mipsel.gpg.key | apt-key add -"
sudo echo "export LANG=C" >> ins.sh
sudo echo "apt-get update" >> ins.sh
sudo echo "apt-get install -y apt-utils dialog locales network-manager lightdm openssh-server vim fonts-wqy-zenhei" >> ins.sh
sudo echo "export LANG=zh_CN.UTF-8" >> ins.sh
sudo echo "/usr/sbin/dpkg-reconfigure locales" >> ins.sh

sudo echo "echo deepin > /etc/hostname" >> ins.sh
sudo echo "echo root:deepin | chpasswd" >> ins.sh
sudo echo "echo '/dev/sdb1 / ext2 defaults 0 1' > /etc/fstab" >> ins.sh

sudo echo "apt-get install -y dbus-x11 startdde deepin-desktop-environment deepin-installer deepin-terminal && apt-get clean" >> ins.sh

sudo cp ins.sh $targetdir
sudo chroot $targetdir /ins.sh

# umount可能失败
sudo umount $targetdir/dev/pts
sudo umount $targetdir/proc

# clear
sudo rm $targetdir/ins.sh $targetdir/mipsel.gpg.key $targetdir/usr/bin/qemu-mipsel-static $targetdir/etc/resolv.conf

sudo rm ins.sh

# only for usb boot
# sudo cp -a boot/* $targetdir/
