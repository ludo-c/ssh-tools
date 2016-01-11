#!/bin/sh
# backup configuration files and send it to a server
# param: server name or IP

tunnel_script="tunnel.sh"
server_directory="backup_tunnel_config"
hostname=$(hostname)
date=$(date +%Y-%m-%d_%H-%M-%S)
archive="/tmp/config_tunnel_${hostname}_${date}.tar.gz"

if [ $# -ne 1 ]; then
	echo "Need server name or IP"
	echo "use: $0 server_name"
	exit 1
fi

server=$1

for script in ~/bin/* ; do
	readlink $script | grep ${tunnel_script} > /dev/null
	if [ $? -eq 0 ]; then
		script_name=$(basename ${script})
		to_be_saved="${to_be_saved} ${script_name}.conf"
	fi
done

eval tar -cvf ${archive} -C ~/.config ${to_be_saved}
scp ${archive} ${server}:${server_directory}
rm ${archive}

