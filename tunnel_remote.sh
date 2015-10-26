#!/bin/sh

# use : remote_port=2222 local_port=22 dest_host="bob@localhost" ./tunnel_remote.sh
# http://artisan.karma-lab.net/faire-passer-trafic-tunnel-ssh

options="ExitOnForwardFailure yes"

while [ true ]; do
	date
	ssh -o "${options}" -nTNR ${remote_port}:localhost:${local_port} ${dest_host}
	sleep 10
done
