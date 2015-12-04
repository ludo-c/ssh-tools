#!/bin/sh
# Create a socks v5 proxy
# Uses socks.conf file with "user", "host", and "port" variables
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh

# returns: 0 ok (connected with 'status')
#          1 bad parameter
#          2 proxy disconnected
#          3 configuration file error
#          4 already running
#          5 error on start
#          6 error on stop

name=$(basename $0)
config_file=${HOME}/.config/${name}.conf

[ ! -d "$(dirname ${config_file})" ] && mkdir -p "$(dirname ${config_file})"
if [ -f "${config_file}" ]; then
	. ${config_file}   # read user, host, local_port and ssh_port
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
	echo ${echo_options} "user=\nhost=\nlocal_port=\n# SSH port (default 22)\nssh_port=22\n# Private key stored in ~/.ssh with no passphrase for restricted remote user (optional)\nidentity_file=\n" > ${config_file}
	echo "config file ${config_file} created, please fill it"
	exit 3
fi

if [ -z "${user}" -o -z "${host}" -o -z "${local_port}" -o -z "${ssh_port}" ]; then
	echo "user, host, local_port and ssh_port variables are needed"
	exit 3
fi

ctl_path="${HOME}/.ssh/${name}-${user}@${host}:${local_port}"
ssh_options="ExitOnForwardFailure=yes"
log_file="/tmp/${name}.log"
status_log_file="/tmp/${name}-status.log"
ssh_identity_file=""
if [ ! -z ${identity_file} ]; then
	ssh_identity_file="-i ${HOME}/.ssh/${identity_file}"
fi

stop() {
	status
	if [ $? -eq 0 ]; then
		echo -n "Stopping ${name}... "
		output=$(ssh -S ${ctl_path} -O exit ${user}@${host} 2>&1)
		if [ $? -eq 0 ]; then  # 255 when socket doest not exist, 0 otherwise
			echo "OK"
		else
			echo "ERROR. ${output}"
			return 6
		fi
	else
		echo "Not running"
	fi
}

start() {
	status
	if [ $? -eq 0 ]; then
		echo "Already running"
		return 4
	fi
	echo -n "Starting ${name}... "
	date >> ${log_file}
	eval ssh -o ${ssh_options} ${ssh_identity_file} -p ${ssh_port} -MS ${ctl_path} -E ${log_file} -nfNTD ${local_port} ${user}@${host}
	if [ $? -ne 0 ]; then
		echo "ERROR. See ${log_file}. Here's a tail:"
		tail ${log_file}
		return 5
	else
		echo "OK"
	fi
}

status() {
	output=$(ssh -S ${ctl_path} -E ${status_log_file} -O check ${user}@${host} 2>&1)
	if [ $? -eq 0 ]; then  # 255 when socket doest not exist, 0 otherwise
		if [ ! -z "$1" ]; then
			# Needs proxychains4 (proxychains-ng)
			latency=$(proxychains4 nmap -sP ${host} 2> /dev/null | grep -Eo '[[:digit:]]+\.[[:digit:]]+s' | tr -d 's')
			echo $latency
		fi
		return 0
	else
		return 2
	fi
}

case $1 in
start)
	start
	exit $?
	;;
stop)
	stop
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
restart)
	stop  # don't care if it fails
	start
	exit $?
	;;
test)
	nc -zw3 localhost ${local_port}
	exit $?
	;;
*)
	echo "Usage: ${name} {start|stop|restart|status|latency|test}" >&2
	exit 1
esac
