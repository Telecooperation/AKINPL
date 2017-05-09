#!/bin/bash

#####################################################
#	This is the build script installing the     #
#	packages not installed by jhalfs.	    #
#####################################################

# check for systemd

if [ -d /etc/systemd/network ]; then

rm /etc/resolv.conf

ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

fi


# dhcp

tar xf dhcp-4.3.4.tar.gz
cd dhcp-4.3.4

patch -Np1 -i ../dhcp-4.3.4-missing_ipv6-1.patch

patch -Np1 -i ../dhcp-4.3.4-client_script-1.patch &&
CFLAGS="-D_PATH_DHCLIENT_SCRIPT='\"/sbin/dhclient-script\"' -D_PATH_DHCPD_CONF='\"/etc/dhcp/dhcpd.conf\"' -D_PATH_DHCLIENT_CONF='\"/etc/dhcp/dhclient.conf\"'" ./configure --prefix=/usr --sysconfdir=/etc/dhcp --localstatedir=/var --with-srv-lease-file=/var/lib/dhcpd/dhcpd.leases --with-srv6-lease-file=/var/lib/dhcpd/dhcpd6.leases --with-cli-lease-file=/var/lib/dhclient/dhclient.leases --with-cli6-lease-file=/var/lib/dhclient/dhclient6.leases
make -j1

make install                   &&
mv -v /usr/sbin/dhclient /sbin &&
install -v -m755 client/scripts/linux /sbin/dhclient-script

cd ..
rm -r dhcp-4.3.4

# OpenSSH

tar xf openssh-7.3p1.tar.gz
cd openssh-7.3p1

install  -v -m700 -d /var/lib/sshd &&
chown    -v root:sys /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' -d /var/lib/sshd -g sshd -s /bin/false -u 50 sshd

./configure --prefix=/usr --sysconfdir=/etc/ssh --with-md5-passwords --with-privsep-path=/var/lib/sshd &&
make

make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-7.3p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* /usr/share/doc/openssh-7.3p1

echo "PermitRootLogin no" >> /etc/ssh/sshd_config

cd ..
rm -r openssh-7.3p1

# LTTng modules

tar xf lttng-modules-latest-2.8.tar.bz2
cd lttng-modules-2.8.3

make 
make modules_install
depmod -a

cd ..
rm -r lttng-modules-2.8.3

# LTTng UST

tar -xf lttng-ust-latest-2.8.tar.bz2
cd lttng-ust-2.8.1

./configure --prefix=/usr &&
make 
make install
ldconfig

cd ..
rm -r lttng-ust-2.8.1

# LTTng tools

tar -xf lttng-tools-latest-2.8.tar.bz2
cd lttng-tools-2.8.2
./configure --prefix=/usr
make
make install
ldconfig

cd ..
rm -r lttng-tools-2.8.2

# traffic 3

git clone https://github.com/rsandila/traffic3.git
cd traffic3

cd 3rdparty
./build.sh
mv ../bin/32bit/Debug/traffic3 /usr/bin

cd ../..
rm -r traffic3


################################
# Put additional packages here #
################################

# Fetch firmware

git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
cd linux-firmware
cp *.ucode /lib/firmware
cp -r rtl_nic /lib/firmware
cd ..
rm -r linux-firmware

