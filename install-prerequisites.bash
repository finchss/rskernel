#!/bin/bash
yum install -y deltarpm
yum upgrade -y

yum install -y psmisc java-devel wget mlocate mc nano ncurses-devel  hmaccalc zlib-devel binutils-devel elfutils-libelf-devel tcpdump strace ltrace wget php-cli  net-tools bc  xmlto  pesign pciutils-devel numactl-devel  audit-libs-devel  elfutils-devel  asciidoc  python-devel  newt-devel perl-ExtUtils-Embed.noarch


setenforce 0
echo -n -e "SELINUX=disabled\nSELINUXTYPE=targeted\n" > /etc/selinux/config
grub2-mkconfig > /boot/grub2/grub.cfg

yum groupinstall -y "Development Tools"

yum upgrade -y
