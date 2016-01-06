#!/bin/sh
# Create a ssh socks proxy or remote|local port forwarding
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
	. ${config_file}   # read all variables
else
	cat > ${config_file} << END
login_name=
hostname=
# Type can be 'remote', 'local' or 'socks'
type=
# For 'remote', 'local' and 'socks'
port=
# For 'remote' and 'local'
hostport=
# SSH port (default 22)
ssh_port=22
# Private key stored in ~/.ssh with no passphrase for restricted remote user (optional)
identity_file=
# Allows remote hosts to connect to local forwarded ports (default no, need GatewayPorts option enabled on server)
pub_fwd_port=no

END
	echo "config file ${config_file} created, please fill it"
	exit 3
fi

if [ -z "${login_name}" -o -z "${hostname}" -o -z "${port}" -o -z "${type}" ]; then
	echo "login_name, hostname, port and type variables are needed in ${config_file}"
	exit 3
fi
if [ "${type}" = "remote" -o "${type}" = "local" ]; then
	if [ -z "${hostport}" ]; then
		echo "hostport variable is needed"
		exit 3
	fi
fi

if [ "${type}" = "remote" ]; then
	tunnel_cmd="-R ${port}:localhost:${hostport}"
elif [ "${type}" = "local" ]; then
	tunnel_cmd="-L ${port}:localhost:${hostport}"
elif [ "${type}" = "socks" ]; then
	tunnel_cmd="-D ${port}"
else
	echo "Bad type, must be 'remote', 'local' or 'socks', found :${type}"
	exit 3
fi

if [ -z "${ssh_port}" ]; then
	ssh_port=22
fi

if [ -z "${pub_fwd_port}" ]; then
	g=""
elif [ "${pub_fwd_port}" = "yes" ]; then
	g="-g"
else
	g=""
fi

lf=/tmp/${name}.pid
ssh_options="-o ExitOnForwardFailure=yes -o ServerAliveInterval=30"
ssh_log_file="/tmp/${name}-ssh.log"
autossh_log_file="/tmp/${name}-autossh.log"
sshlogin_log_file="/tmp/${name}-sshlogin.log"
ssh_identity_file=""
if [ ! -z ${identity_file} ]; then
	ssh_identity_file="-i ${HOME}/.ssh/${identity_file}"
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
				latency=$(nmap -sP ${hostname} | grep -Eo '[[:digit:]]+\.[[:digit:]]+s' | tr -d 's')
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
		eval AUTOSSH_GATETIME=0 AUTOSSH_PIDFILE=${lf} AUTOSSH_LOGFILE=${autossh_log_file} \
			autossh -f -M0 -- ${ssh_options} ${ssh_identity_file} -E ${ssh_log_file} \
			${g} -nTN ${tunnel_cmd} -p ${ssh_port} ${login_name}@${hostname}
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
	eval ssh ${ssh_identity_file} -no ConnectTimeout=5 -E ${sshlogin_log_file} \
		-p ${ssh_port} ${login_name}@${hostname} exit > /dev/null 2>&1
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
