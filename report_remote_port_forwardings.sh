#!/bin/sh

report_remote_port_forwardings()
{

	echo
	echo "REMOTE PORT FORWARDING"
	echo
	echo "You set up the following remote port forwardings:"
	echo

	ps -f -p $(lsof -t -a -i -c '/^ssh$/' -u$USER -s TCP:ESTABLISHED) | awk '
	NR == 1 || /R (\S+:)?[[:digit:]]+:\S+:[[:digit:]]+.*/
	'
}

report_remote_port_forwardings

