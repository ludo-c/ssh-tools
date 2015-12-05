#!/bin/sh

name=$(basename $0)
bin_dir="${HOME}/bin"
systemd_conf_dir="/etc/systemd/system"

[ ! -d "$bin_dir" ] && mkdir ${bin_dir}

for script in *; do
	# link only files that are not already linked
	# only executable files
	# do not create link for this script
	if [ ! -f ${bin_dir}/${script} ] && \
	   [ -x ${script} ] && \
	   [ "${script}" != "${name}" ]; then
		ln -s ${PWD}/${script} ${bin_dir}
		echo "link created for ${script}"
	fi
done

type systemctl > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
	for script in *.service; do
		if [ ! -f ${systemd_conf_dir}/${script} ];then
			# in order to "enable" service the file have to be copied, not symlinked
			cp ${PWD}/${script} ${systemd_conf_dir}
			if [ $? -eq 0 ]; then
				echo "${script} copied"
				echo "enable it with :"
				echo "sudo systemctl daemon-reload"
				echo "sudo systemctl enable" ${script}
			else
				echo "Error while copying to ${systemd_conf_dir}. Need to be root"
			fi
		fi
	done
else
	echo "Systemd isn't available on this system. Startup files will not be installed"
fi
