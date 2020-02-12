#!/bin/sh

report_local_port_forwardings()
{

	# -a ands the selection criteria (default is or)
	# -i4 -i6 limits to ipv4 and ipv6 internet files
	# -P inhibits the conversion of port numbers to port names
	# -c /regex/ limits to commands matching the regex
	# -u$USER limits to processes owned by $USER
	# http://man7.org/linux/man-pages/man8/lsof.8.html
	# https://stackoverflow.com/q/34032299

	echo
	echo "LOCAL PORT FORWARDING"
	echo
	echo "You set up the following local port forwardings:"
	echo

	lsof -a -i4 -i6 -P -c '/^ssh$/' -u$USER -s TCP:LISTEN

	echo
	echo "The processes that set up these forwardings are:"
	echo

	ps -f -p $(lsof -t -a -i4 -P -c '/^ssh$/' -u$USER -s TCP:LISTEN)
}

report_local_port_forwardings

