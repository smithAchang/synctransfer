#! /bin/bash
# Deploying sendmail service
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

ensurePython3=$(rpm -qa python3 | wc -l)

if [ $ensurePython3 -eq 0 ];then
  echo "python3 must be provided firstly!"
  exit 1
fi


systemctl is-enabled ftpsendmail >/dev/null 2>&1

if [ $? -ne 0 ];then
  echo "enable sendmail service ..."
  systemctl link $HOME/ftpsendmail.service
  systemctl enable ftpsendmail.service
fi



popd

