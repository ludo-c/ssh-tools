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
#           3 configuration file error

name=$(basename $0)

config_file=${HOME}/.config/${name}.cfg
if [ -f "${config_file}" ]; then
	. ${config_file}   # read remote_port, local_port and dest_host
else
	echo -e "remote_port=\nlocal_port=\ndest_host=\n" > ${config_file}
	echo "config file ${config_file} created, please fill it"
	exit 3
fi

if [ -z "${remote_port}" -o -z "${local_port}" -o -z "${dest_host}" ]; then
	echo "remote_port, local_port, and dest_host variables are needed"
	exit 3
fi

lf=/tmp/${name}.pid
ssh_options="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30"

if [ "$#" -ne 3 ]; then
	echo "Bad parameters"
	echo "Usage : ${name} <remote_port> <local_port> <dest_host>"
	echo "eg : ${name} 2222 22 bob@host"
	exit 2
fi

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

# In many ways ServerAliveInterval may be a better solution than the monitoring port.
eval autossh -M0 ${ssh_options} -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
