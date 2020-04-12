#!/bin/sh

# Author : M Rahman
# Copyright (c) shadikur.com
#OS: CentOS 7 - 64 bit System
# Script follows here: 

echo "Removing Firewalld...\\nn"
yum remove firewalld -y

echo "Dsabling SELinux...\n\n"
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config

echo "Check for SEStatus.. \n\n"
sestatus

echo "Updating CentOS core ... \n"
yum -y update

echo "Installing Dev Tools... \n\n"
yum -y groupinstall core base "Development Tools"

echo "Adding Asterisk User... \n\n"
adduser asterisk -m -c "Asterisk User"

echo "Installing dependencies...\n\n"
yum -y install lynx tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb \
  httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie \
  cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo \
  libuuid-devel

echo "Installing PHP 5.6 Repository... \n"
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

echo "Installaing PHP is in progress ... \n"
yum remove php* -y
yum install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap -y

echo "Installing Nodjs ... \n"
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs 

echo "Setting Maria-DB on startup and starting now ... \n\n"
systemctl enable mariadb.service
systemctl start mariadb

echo "Setting Apache on startup and starting now ... \n\n"
systemctl enable httpd.service
systemctl start httpd.service

echo "Installing Console_Getopt ... \n"
pear install Console_Getopt

echo "Downloading Asterisk Files ... \n"
cd /usr/src
#wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
#wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-14-current.tar.gz

echo "Compile and install jansson ... \n\n"
cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

echo "Compile and Install Asterisk ... \n"
cd /usr/src
tar xvfz asterisk-14-current.tar.gz
rm -f asterisk-*-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh
make menuselect

