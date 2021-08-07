#! /bin/bash
# Run  deleting ftpin area old files
# author: channgyunlei

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME="/home/ftplocaluser"

function issuperpullfile()
{
  for superfile in "${maybe_superpullfiles[@]}" ; do
     if [ "$1" = "$superfile" ];then
	     return 1
     fi
  done

  return 0
}

# get super ftp user pull log
homedirs=$(cat /etc/vsftpd/virtualuser_conf/ftpsuper_* | grep local_root | grep -v "=./ftpin" | awk -F= '{print $2}')
FTPSUPER_LOG=$(cat `ls -rt /var/log/vsftpd.log*` | grep -e "ftpsuper_.*OK DOWNLOAD")
declare -A superHomeMap

ftpsuper_configfiles=(/etc/vsftpd/virtualuser_conf/ftpsuper_*)

for super_conffile in "${ftpsuper_configfiles[@]}" ;do
   homedir=$(cat $super_conffile | grep local_root | awk -F= '{print $2}')
   supername=${super_conffile##/*/}
   superHomeMap["$supername"]="$homedir"
done

# may has space in path name or dir name
OLDIFS="$IFS"
IFS=$'\n'
declare -a maybe_superpullfiles

for super_pullfilelog in $FTPSUPER_LOG ; do
    supername=$(echo "$super_pullfilelog" | awk -F, '{print $1}' | awk '{print $4}')
    supername=${supername#*\[}
    supername=${supername%*\]}

    superfile=$(echo "$super_pullfilelog" | awk -F, '{print $2}')
    superfile=${superfile#*\"}
    superfile=${superfile%*\"}

    if [ -n "${superHomeMap[$supername]}" ];then
      wholepath="${superHomeMap[$supername]}$superfile"
      maybe_superpullfiles+=("$wholepath")
    fi
done

# main loop to delete non superftpuser pull files!!!
# ftpsuper_* home dir must in >=2 depth level
for file in $(find $HOME/ftpin/ -mindepth 2 -type f -cmin +120);do
   issuperpullfile "$file"

   if [ $? -eq 1 ];then
     echo "cannot rm file $file ..."
   else
     echo "can rm file $file ..."
     yes |rm -f "$file"
   fi

done



# main loop to delete empty dirs
for tmpdir in $(find $HOME/ftpin/ -mindepth 3 -type d | sort -r); do

   if [ `ls -A "$tmpdir" | wc -w` -eq 0 ];then
     echo "can rm dir $tmpdir ..."
     yes | rm -rf "$tmpdir"
   else
     echo "cannot rm non-empty dir: $tmpdir ..."
   fi

done

exit 0


