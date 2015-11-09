#!/bin/sh
# Create a ssh remote port forwarding
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh
#
# If you have trouble reconnecting to the server with :
# "Error: remote port forwarding failed for listen port xxxx"
# add "ClientAliveInterval 60" in your sshd configuration (server side)
# see: http://unix.stackexchange.com/questions/3026/what-do-the-options-serveraliveinterval-and-clientaliveinterval-in-sshd-conf

# Returns : 0 ok
#           1 bad parameters
#           2 process is already running (except for 'status')
#           3 configuration file error

name=$(basename $0)
config_file=${HOME}/.config/${name}.cfg

[ ! -d "$(dirname ${config_file})" ] && mkdir -p "$(dirname ${config_file})"
if [ -f "${config_file}" ]; then
	. ${config_file}   # read remote_port, local_port and dest_host
else
	# Does shell need '-e' to interpret backslash escapes
	output=$(echo "test\necho" | wc -l)
	rc=$?
	echo_options=""
	if [ "${rc}" -eq 0 ] && [ "${output}" -ne 1 ]; then
		echo_options=""
	else
		echo_options="-e"
	fi
	echo ${echo_options} "remote_port=\nlocal_port=\ndest_host=\n" > ${config_file}
	echo "config file ${config_file} created, please fill it"
	exit 3
fi

if [ -z "${remote_port}" -o -z "${local_port}" -o -z "${dest_host}" ]; then
	echo "remote_port, local_port, and dest_host variables are needed"
	exit 3
fi

lf=/tmp/${name}.pid
ssh_options="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30"

# return 2 if running, 0 otherwise
status() {
	# http://stackoverflow.com/questions/1440967/how-do-i-make-sure-my-bash-script-isnt-already-running
	# create empty lock file if none exists
	touch ${lf}
	read lastPID < ${lf}
	# if lastPID is not null and a process with that pid exists, exit
	if [ ! -z "${lastPID}" -a -d /proc/${lastPID} ]; then
		# check that the process is not a recycled one (at least, it's autossh)
		eval grep autossh /proc/${lastPID}/cmdline > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			return 2
		fi
	fi
}

send_signal() {
	status
	rc=$?
	if [ ${rc} -ne 0 ]; then
		read lastPID < ${lf}
		case $1 in
			stop)
				# SIGTERM
				signal="15"
				;;
			restart)
				# SIGUSR1
				signal="10"
				;;
			*)
				# impossible case
				return 1
				;;

		esac
		eval kill -${signal} ${lastPID}
	else
		echo "${name} is not running"
		return 4
	fi
}

start() {
	echo -n "Starting... "
	status
	rc=$?
	if [ ${rc} -ne 0 ]; then
		echo "Failed. Already running"
		return 2
	else
		# man: In many ways ServerAliveInterval may be a better solution than the monitoring port.
		eval AUTOSSH_PIDFILE=${lf} autossh -f -M0 ${ssh_options} -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
		if [ $? -eq 0 ]; then
			echo "OK"
		else
			echo "ERROR"
		fi
	fi
}

case $1 in
	start)
		start
		exit $?
		;;
	stop|restart)
		send_signal $1
		exit $?
		;;
	status)
		status
		rc=$?
		if [ "${rc}" -eq 0 ]; then
			echo "inactive"
		else
			echo "active"
		fi
		;;
	*)
		echo "Usage: ${name} {start|stop|restart|status}" >&2
		exit 1
		;;
esac
