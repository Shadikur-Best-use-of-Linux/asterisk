#!/bin/sh

# Author : M Rahman
# Copyright (c) shadikur.com
#OS: CentOS 7 - 64 bit System
# Script follows here: 

#All the variables
bold=$(tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2)

echo "${green}Adding 2GB of Swap Memory. ${normal}"
echo "\n${bold}Processing...Please wait.${normal}"
cd /var
touch swap.img
chmod 600 swap.img
dd if=/dev/zero of=/var/swap.img bs=2048k count=1000
echo  "${bold}${green}SWAP Processed Successfully${normal}"
mkswap /var/swap.img
swapon /var/swap.img
echo "/var/swap.img    none    swap    sw    0    0" >> /etc/fstab
sysctl -w vm.swappiness=30
echo  "${bold}${green}SWAP Memory added successfully.${normal}"
free -m

echo "${green}Removing Firewalld...${normal}"
yum remove firewalld -y

echo "Dsabling SELinux...\n\n"
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config

echo "${green}Check for SEStatus.. ${normal}"
sestatus

echo "${green}Updating CentOS core ... ${normal}"
yum -y update

echo "${green}Installing Dev Tools... ${normal}"
yum -y groupinstall core base "Development Tools"

echo "${green}Adding Asterisk User... ${normal}"
adduser asterisk -m -c "Asterisk User"

echo "${green}Installing dependencies... ${normal}"
yum -y install lynx tftp-server unixODBC mysql-connector-odbc mariadb-server mariadb \
  httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie \
  cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo \
  libuuid-devel

echo "${green}Installing PHP 5.6 Repository... ${normal}"
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

echo "${green}Installaing PHP is in progress ... ${normal}"
yum remove php* -y
yum install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap -y

echo "${green}Installing Nodjs ... ${normal}"
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs 

echo "${green}Setting Maria-DB on startup and starting now ... ${normal}"
systemctl enable mariadb.service
systemctl start mariadb

echo "${green}Setting Apache on startup and starting now ... ${normal}"
systemctl enable httpd.service
systemctl start httpd.service

echo "${green}Installing Console_Getopt ... ${normal}"
pear install Console_Getopt

echo "${green}Downloading Asterisk Files ... ${normal}"
cd /usr/src
#wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
#wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

echo "${green}Compile and install jansson ... ${normal}"
cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

echo "${green}Compile and Install Asterisk ... ${normal}"
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

echo "${green}Setting up correct permission ... ${normal} "
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/

echo "${green}Installing and configuring enviroment for FreePBX ... ${normal} "
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service

echo "${green}Download and install FreePBX ... ${normal} "
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-14.0-latest.tgz
tar xfz freepbx-14.0-latest.tgz
rm -f freepbx-14.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n

echo "${green}Cleaning downloads ... ${normal}"
rm -rf /usr/src/asterisk*
rm -rf /usr/src/v*
chown -R root:root /var/spool/mqueue/
chmod 755 -R /var/spool/mqueue/
echo "${green}${bold}Installation complete. Please visit the GUI through web browser. ${normal}"

