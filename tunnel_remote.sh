#!/bin/sh
# Create a ssh remote port forwarding
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh
#
# If you have trouble reconnecting to the server with :
# "Error: remote port forwarding failed for listen port xxxx"
# add "ClientAliveInterval 60" in your sshd configuration (server side)
# see: http://unix.stackexchange.com/questions/3026/what-do-the-options-serveraliveinterval-and-clientaliveinterval-in-sshd-conf

# Returns : 0 ok
#           1 process is already running
#           2 bad parameters

name=$(basename $0)
lf=/tmp/${name}.pid
ssh_options="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30"

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
	# check that the process is not a recycled one
	grep ${name} /proc/${lastPID}/cmdline > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "${name} already running"
		exit 1
	fi
fi

# save my pid in the lock file
echo $$ > ${lf}

while [ true ]; do
	date
	eval ssh ${ssh_options} -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
	sleep 10
done
