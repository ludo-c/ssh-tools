#!/bin/bash
# http://superuser.com/questions/248389/list-open-ssh-tunnels
# On the server side, shows remote tunnel made on it.
# If there is a port 6010 from no where, it's just ssh X11 forwarding.
# I add "grep IPv4 |" to avoid a bad line added by ipv6

if [ "${USER}" != "root" ]; then
	echo "you must be root (or use sudo)"
	exit 1
fi

lsof -i -n | egrep '\<sshd\>' | grep -v ":ssh" | grep LISTEN | sed 1~2d | awk '{ print $2}' | while read line; do sudo lsof -i -n | egrep $line | grep IPv4 | sed 3~3d | sed 's/.*->//' | sed 's/:......*(ESTABLISHED)//' | sed 's/.*://' | sed 's/(.*//' | sed 'N;s/\n/:/' 2>&1 ;done
