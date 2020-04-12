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
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

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
tar xvfz asterisk-13-current.tar.gz
rm -f asterisk-*-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh
make menuselect
make
make install
make config
ldconfig
chkconfig asterisk off

echo "Setting up correct permission ... \n\n"
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/

echo "Installing and configuring enviroment for FreePBX ... \n\n"
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service

echo "Download and install FreePBX ... /n/n"
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar xfz freepbx-14.0-latest.tgz
rm -f freepbx-14.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n

echo "Cleaning downloads ... \n"
rm -rf /usr/src/asterisk*
rm -rf /usr/src/v*
echo "Installation complete. Please visit the GUI through web browser. \n\n"

