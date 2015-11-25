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
#           2 process is already running
#           3 configuration file error
#           4 login error

name=$(basename $0)
config_file=${HOME}/.config/${name}.conf

[ ! -d "$(dirname ${config_file})" ] && mkdir -p "$(dirname ${config_file})"
if [ -f "${config_file}" ]; then
	. ${config_file}   # read remote_port, local_port, user and dest_host
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
	echo ${echo_options} "remote_port=\nlocal_port=\nuser=\ndest_host=\n# Private key stored in ~/.ssh with no passphrase for restricted remote user (optional)\npriv_key=\n" > ${config_file}
	echo "config file ${config_file} created, please fill it"
	exit 3
fi

if [ -z "${remote_port}" -o -z "${local_port}" -o -z "${dest_host}" -o -z "${user}" ]; then
	echo "remote_port, local_port, user, and dest_host variables are needed"
	exit 3
fi

lf=/tmp/${name}.pid
ssh_options="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30"
ssh_log_file="/tmp/${name}-ssh.log"
autossh_log_file="/tmp/${name}-autossh.log"
sshlogin_log_file="/tmp/${name}-sshlogin.log"
ssh_priv_key=""
if [ ! -z ${priv_key} ]; then
	ssh_priv_key="-i ${HOME}/.ssh/${priv_key}"
fi

# return 0 if running, 2 otherwise
status() {
	# http://stackoverflow.com/questions/1440967/how-do-i-make-sure-my-bash-script-isnt-already-running
	last_pid=""
	rc=2
	if [ -f ${lf} ]; then
		read last_pid < ${lf}
	fi
	# if last_pid is not null and a process with that pid exists, exit
	if [ ! -z "${last_pid}" -a -d /proc/${last_pid} ]; then
		# check that the process is not a recycled one (at least, it's autossh)
		eval grep autossh /proc/${last_pid}/cmdline > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			rc=0
			if [ ! -z "$1" ]; then
				latency=$(nmap -sP ${dest_host} | grep -Eo '[[:digit:]]+\.[[:digit:]]+s' | tr -d 's')
				echo ${latency}
			fi
		fi
	fi
	return ${rc}
}

send_signal() {
	status
	if [ $? -eq 0 ]; then
		read last_pid < ${lf}
		case $1 in
		stop)
			# SIGTERM
			kill -15 ${last_pid}
			sleep 1
			status
			if [ $? -eq 0 ]; then
				# SIGKILL
				kill -9 ${last_pid}
				rm ${lf}
			fi
			;;
		restart)
			# SIGUSR1
			kill -10 ${last_pid}
			;;
		*)
			# impossible case
			return 1
			;;
		esac
	else
		echo "${name} is not running"
		return 4
	fi
}

start() {
	echo -n "Starting... "
	status
	if [ $? -eq 0 ]; then
		echo "Failed. Already running"
		return 2
	else
		test_login
		if [ $? -ne 0 ]; then
			echo "Login error:"
			tail ${sshlogin_log_file}
			return 4
		fi

		# man: In many ways ServerAliveInterval may be a better solution than the monitoring port.
		# some versions of autossh doesn't set the AUTOSSH_GATETIME to 0 when -f is used
		eval AUTOSSH_GATETIME=0 AUTOSSH_PIDFILE=${lf} AUTOSSH_LOGFILE=${autossh_log_file} autossh -f -M0 -- ${ssh_options} ${ssh_priv_key} -E ${ssh_log_file} -nTNR ${remote_port}:localhost:${local_port} ${user}@${dest_host}
		if [ $? -eq 0 ]; then
			echo "OK"
		else
			# in case autossh is not installed. In all others cases autossh will return OK
			echo "ERROR"
		fi
	fi
}

# Return 0 if login OK, 4 otherwise
test_login() {
	# ssh return:
	#   255 if login is impossible
	#   1 if login is /bin/false
	#   0 if login OK
	date >> ${sshlogin_log_file}
	ssh -q ${ssh_priv_key} -E ${sshlogin_log_file} ${user}@${dest_host} 2>&1 > /dev/null
	if [ $? -eq 255 ]; then
		return 4
	else
		return 0
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
	if [ ${rc} -eq 0 ]; then
		echo "active"
	else
		echo "inactive"
	fi
	exit ${rc}
	;;
latency)
	status latency
	exit $?
	;;
test)
	test_login
	exit $?
	;;
*)
	echo "Usage: ${name} {start|stop|restart|status|latency|test}" >&2
	exit 1
	;;
esac
