#!/bin/sh

# use : remote_port=2222 local_port=22 dest_host="bob@localhost" ./tunnel_remote.sh
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh

options="ExitOnForwardFailure yes"
name=$(basename $0)
lf=/tmp/${name}_pid_lock_file

# http://stackoverflow.com/questions/1440967/how-do-i-make-sure-my-bash-script-isnt-already-running
# create empty lock file if none exists
touch $lf
read lastPID < $lf
# if lastPID is not null and a process with that pid exists, exit
if [ ! -z "$lastPID" -a -d /proc/$lastPID ]; then
	echo "${name} already running"
	exit 1
fi

# save my pid in the lock file
echo $$ > $lf

while [ true ]; do
	date
	ssh -o "${options}" -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
	sleep 10
done
