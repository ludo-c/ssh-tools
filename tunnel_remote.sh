#!/bin/sh
# Create a ssh remote port forwarding
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh
# Returns : 0 ok
#           1 process is already running
#           2 bad parameters

name=$(basename $0)
lf=/tmp/${name}.pid
ssh_options="ExitOnForwardFailure=yes"

if [ "$#" -ne 3 ]; then
	echo "Bad parameters"
	echo "Usage : ${name} <remote_port> <local_port> <dest_host>"
	echo "eg : ${name} 2222 22 bob@host"
	exit 2
fi

remote_port=$1
local_port=$2
dest_host=$3

# http://stackoverflow.com/questions/1440967/how-do-i-make-sure-my-bash-script-isnt-already-running
# create empty lock file if none exists
touch ${lf}
read lastPID < ${lf}
# if lastPID is not null and a process with that pid exists, exit
if [ ! -z "${lastPID}" -a -d /proc/${lastPID} ]; then
	echo "${name} already running"
	exit 1
fi

# save my pid in the lock file
echo $$ > ${lf}

while [ true ]; do
	date
	ssh -o ${ssh_options} -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
	sleep 10
done
