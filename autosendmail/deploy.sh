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


echo "enable sendmail service ..."
systemctl link $HOME/ftpsendmail.service
systemctl enable ftpsendmail.service
popd

