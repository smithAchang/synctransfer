#! /bin/bash
# Run  deleting ftpin area old files
# author: channgyunlei
# design: this filnle is created for Liux Middle-Transfer System deploying

PRG="$0"

while [ -h "$PRG" ]; do
	ls=`ls -ld "$PRG"`
	link=`expr "$ls" : '.*-> \(.*\)$'`
	if expr "$link" : '.*/.*' > /dev/null; then
		PRG="$link"
	else
		PRG=`dirname "$PRG"`/"$link"
	fi
done


# get standard environment 
PRGDIR=`dirname "$PRG"`

# base dir
pushd "$PRGDIR"
HOME=`pwd`
LOCAL_USER="ftplocaluser"

#use the global settings
source scripts/global.sh

# set host name
hostnamectl set-hostname "ftptransfer"

# install need rpms

if [ -z "`rpm -qa vsftpd`" ] ;then
	rpm -ivh rpms/vsftpd-*.rpm
else
	echo "vsftpd has installed ..."
fi

if [ -z "`rpm -qa rsync`" ] ;then
	rpm -ivh rpms/rsync-*.rpm
else
	echo "rsync has installed ..."
fi


# create ftp local user,other config files use his home dir
echo "add  local mapping user for  ftp working dir ..."
useradd -rm -s /sbin/nologin $LOCAL_USER

# to allow change the ftp dir
chmod +x /home/$LOCAL_USER

su -s /bin/bash -c "mkdir -p ~/ftpin ~/ftpout ~/tools" $LOCAL_USER

# use as rsync file lock to avoid dulicate runningg
su -s /bin/bash -c "touch ~/rsync.lock" $LOCAL_USER

# no create home dir for common ftp users
adduser -rM -s /sbin/nologin ftpin
adduser -rM -s /sbin/nologin ftpout
adduser -rM -s /sbin/nologin tools

echo "copy the vsftp config files,specially for using virtual users ..."
cp -f vsftpd_cfg/vsftpd.conf vsftpd_cfg/access.conf vsftpd_cfg/virtualuser.plain.txt  /etc/vsftpd/
chmod 644 /etc/vsftpd/vsftpd.conf /etc/vsftpd/access.conf
chmod 600 /etc/vsftpd/virtualuser.plain.txt

cp -rf virtualuser_conf/ /etc/vsftpd/
chmod 644 /etc/vsftpd/virtualuser_conf/*


# autosendmail
cp -rf autosendmail/ /etc/vsftpd/scripts/
chmod 744 /etc/vsftpd/scripts/autosendmail/*.sh

cp -rf scripts/ /etc/vsftpd/
chmod 755 /etc/vsftpd/scripts/*

chmod 644 cron.d/*
cp -f cron.d/* /etc/cron.d/

# as logrotate providing scipts
cp -f scripts/rmftpinoldfiles.sh /etc/cron.daily/
chmod 744 /etc/cron.daily/rmftpinoldfiles.sh




echo "#%PAM-1.0
auth requisite pam_userdb.so db=/etc/vsftpd/virtualuser
account requisite pam_access.so accessfile=/etc/vsftpd/access.conf" > /etc/pam.d/vsftpd.virtual

chmod 644 /etc/pam.d/vsftpd.virtual

# create config for ftp common users
reform_userdb
reform_accessfile


echo "config vsftpd log ..."

echo "# vsftpd log to rsysloog for supporting chinese charset
ftp.* /var/log/vsftpd.log;RSYSLOG_FileFormat
" >> /etc/rsyslog.conf

systemctl restart rsyslog

echo "/var/log/vsftpd.log {
       # ftpd doesn't hanle SIGHUP properly
       weekly
       nocompress
       missingok
       # long term for audit
      rotate 60
}
" > /etc/logrotate.d/vsftpd

chmod 644 /etc/logrotate.d/vsftpd

echo "enable vsftpd autostart ..."
systemctl enable vsftpd

echo "stop firewalld ..."
systemctl stop firewalld
systemctl disable firewalld

