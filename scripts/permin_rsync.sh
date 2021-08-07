#! /bin/bash
# Run  the rsync jobs
# author: channgyunlei
# design: to avoid replace ftpin existing files; to avoid some uploading files
# design: rm old files in ftpout area  when finishing sync

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME="/home/ftplocaluser"

# unit:minute
filter_threshold=1
filters=""

# exclude the uploading files in ftpout area
for exclude_file in `find $HOME/ftpout -type f -cmin -$filter_threshold`; do
    filters="$filters--filter='exclude $(basename $exclude_file)' "
done

#echo "filter:$filters"
start_seconds=$(date +%s)
if [ -z "$filters" ];then
  cmd="rsync -rv --ignore-existing $HOME/ftpout/ $HOME/ftpin"
else
  cmd="rsync -rv --ignore-existing $filters $HOME/ftpout/ $HOME/ftpin"
fi

#echo "cmd:$cmd"
# excute cmd
$cmd

end_seconds=$(date +%s)

excute_time=$(($end_seconds - $start_seconds))

delete_threshold=$(($filter_threshold + excute_time/60 + 1 + 1))

# remove old files in ftpout area after sync
find $HOME/ftpout/ -mindepth 3 -mmin +$delete_threshold -print0 | xargs -0 /bin/rm -rf

# only allow personal dir exists
find $HOME/ftpout/ -mindepth 2 -maxdepth 2 -mmin +$delete_threshold -type f -print0 | xargs -0 /bin/rm -rf
