#! /bin/bash
# author: channgyunlei
# design: admin for vsftpd config


# base dir
# resolve links $0 may be a softlink
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

HOME="/home/ftplocaluser"

# Get standard environment variables
PRGDIR=`dirname "$PRG"`
pushd "$PRGDIR"
HOME=`pwd`


# use the global settings
source ./global.sh

function menu()
{
 cat <<eof
*****************************************
*                MENU                   *

*    1.add
*    2.delete
*    3.modify passwd

*     Any Other exit                    *
*****************************************
eof
}


# for ftpsuper_users
function configftpprivileges()
{
 dstfile="/etc/vsftpd/virtualuser_conf/$ftpuser"
 echo "local_root=$ftphome
virtual_use_local_privs=NO
write_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
anon_upload_enable=NO
anon_world_readable_only=YES">$dstfile

chmod 644 $dstfile
}


function deluserinplaindb()
{
  for linenum in `sed -n "/^$ftpuser$/=" $PLAIN_DB`
  do
	  let odd=$linenum%2
	  if [ $odd -eq 1 ]
	  then
           next_linenum=`expr $linenum + 1`
	   sed -i "${linenum},${next_linenum}d" $PLAIN_DB
	  fi
  done
}

function modifyuserpwdinplaindb()
{
 echo "modify ftpuser passwd for $ftpuser"
 for linenum in `sed -n "/^$ftpuser$/=" $PLAIN_DB`
 do
	 let odd=$linenum%2
	 echo "find $ftpuser @$linenum"
	 if [ $odd -eq 1 ]
	 then
		 sed -i "/^${ftpuser}$/{n;s/.*/${ftppasswd}/}" $PLAIN_DB
	 fi
 done

}


function addftpsuperx()
{
 answer='n'
 while [ "$answer" != "y" ]
 do
    validflag=""
    while [ -z "$validflag" ]
    do
	    read -p "please input your ftpuser name(e.g. ftpsuper_xxx):" ftpuser
	    validflag=$(echo $ftpuser | grep -e $REGX_FTPSUPER)
	    if [ -z "$validflag" ];then
		    echo "The input user not valid! $ftpuser"
		    continue
	    fi
    done

    validflag=`sed -n "/^$ftpuser$/=" $PLAIN_DB`
    if [ -n "$validflag" ];then
	    echo "The input user($ftpuser) is duplicated with existed!!"
	    continue
    fi

    validflag=""
    while [ -z "$validflag" ]
    do
	    read -p "please input your ftpsuer password($REGX_PWD):" ftppasswd
	    validflag=$(echo "$ftppasswd" | grep -e $REGX_PWD)
	    if [ -z "$validflag" ];then
		    echo "The input passwd not valid! $ftppasswd"
		    continue
	    fi
    done

    validflag=""
    while [ -z "$validflag" ]
    do
	    read -p "please input your ftpsuper home dir(eg. level2Dir/level3Dir):" ftphome

	    # form the whole path
	    ftphome="/home/$REAL_LOCAL_USER/ftpin/$ftphome"
	    # is dir and readable
	    su - $REAL_LOCAL_USER -s /bin/sh -c "test -d $ftphome -a -r $ftphome"
            if [ $? -ne 0 ];then
		    echo "The input home dir without privileges! $ftphome"
		    continue
            else
              validflag="success"
	    fi
    done

    cat <<eof
***Please Check all input info******************************************
+ user:$ftpuser
+ passwd:$ftppasswd
+ home:$ftphome
eof
   read -p "Is all the paras OK?(y or n):" answer
   # may input agin
 done
 

 echo $ftpuser >> $PLAIN_DB
 echo $ftppasswd >> $PLAIN_DB

 configftpprivileges
 reform_userdb
 reform_accessfile

 # add system account to crack pam
 useradd -r -M -s /sbin/nologin $ftpuser

 echo "add $ftpuser ok!"
 echo ""
}


function delftpsuperx()
{
   read -p "please input your ftp superuser name(ftpsuper_xxx for delete):" ftpuser
   validflag=$(echo $ftpuser |grep -e $REGX_FTPSUPER)

   if [ -z "$validflag" ];then
	   echo "user is not valid! username:$ftpuser"
	   exit 1
   fi

   #only need linenum
   deluserinplaindb

   # del privileges file
   dstfile="/etc/vsftpd/virtualuser_conf/$ftpuser"
   if [ -e "$dstfile" ];then
	   rm -f "$dstfile"
   fi

   reform_userdb
   reform_accessfile
   userdel $ftpuser

   echo "delete $ftpuser ok!"
   echo ""
}

function modifyftpsuperxpwd()
{

 answer='n'

 while [ "$answer" != "y" ]
 do
	 validflag=""
	 while [ -z "$validflag" ]
	 do
		 read -p "please input your ftpuser name(ftpsuper_xxx for modifying pwd):" ftpuser
		 validflag=$(echo $ftpuser | grep -e $REGX_FTPSUPER)
		 if [ -z "$validflag" ];then
		    echo "The input user not valid! $ftpuser"
		    continue
		 fi
	 done

	 validflag=`sed -n "/^$ftpuser$/=" $PLAIN_DB`

	 if [ -z "$validflag" ];then
		 echo "The input user($ftpuser) is not existed!!"
		 return 
	 fi

	 validflag=""

	 while [ -z "$validflag" ]
	 do 
		 read -p "please input your new ftpuser password($REGX_PWD):" ftppasswd
		 validflag=$(echo $ftppasswd | grep -e $REGX_PWD)
		 if [ -z "$validflag" ];then
			 echo "The input passwd not valid! $ftppasswd"
			 continue
		 fi
	 done

	 break
 done

 modifyuserpwdinplaindb

 #
 reform_userdb

}


function usage()
{
 read -p "please input your choice:" choice
 case $choice in
	 1)
		 addftpsuperx
		 ;;
	 2)
		 delftpsuperx
		 ;;
	 3)
		 modifyftpsuperxpwd
		 ;;
	 *)
		 exit 0
		 ;;
 esac
}

function main()
{
  while true
  do 
	  menu
	  usage
  done
}


# run main
main

