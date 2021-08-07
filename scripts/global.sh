#! /bin/bash
# author: channgyunlei
# design: vsftpd global settings,specially the user db section!

HOME="/home/ftplocaluser"

# the global access restricted rules
PLAIN_DB=/etc/vsftpd/virtualuser.plain.txt
REGX_FTPSUPER="^ftpsuper_[0-9A-Za-z]\+$"
REGX_PWD="^[0-9A-Za-z_@.!#]\+$"
REGX_FUZZY_SUPER="^ftpsuper_.*"

# must keep the same when changed
REAL_LOCAL_USER="ftplocaluser"

innernetIPAllowed=("::ffff:172.0.0.0/104")
outernetIPAllowed=("::ffff:10.0.0.0/104")


function reform_userdb()
{
 echo "config user db"
 dstfile="/etc/vsftpd/virtualuser.db.swp"
 db_load -T -t hash -f $PLAIN_DB  $dstfile
 cp -f $dstfile /etc/vsftpd/virtualuser.db && rm -f $dstfile
 chmod 644 /etc/vsftpd/virtualuser.db

}

function add_userallowed()
{
  for allowed in $2
  do
     echo "+:$1:$allowed" >> $3
  done

}

function reform_accessfile()
{
 echo "config access.conf"
 dstfile="/etc/vsftpd/access.conf.swp"
 echo "# add special" > $dstfile

 add_userallowed "ftpout" ${outernetIPAllowed[*]} $dstfile
 add_userallowed "ftpin" ${innernetIPAllowed[*]} $dstfile

 for line in `grep -e $REGX_FUZZY_SUPER $PLAIN_DB`
 do	 
   add_userallowed $line ${outernetIPAllowed[*]} $dstfile
 done

 echo "
# tools user only has read privelege,share for inner_net and outer_net
+:tools:ALL
# All other users should be denied to get access 
-:ALL:ALL" >> $dstfile

 # replace the old config file
 cp -f $dstfile /etc/vsftpd/access.conf && rm -f $dstfile
 chmod 644 /etc/vsftpd/access.conf

}
