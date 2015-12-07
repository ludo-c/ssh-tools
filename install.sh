#!/bin/sh

name=$(basename $0)
bin_dir="${HOME}/bin"
systemd_conf_dir="${HOME}/.config/systemd/user"

[ ! -d "${bin_dir}" ] && mkdir ${bin_dir}

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
echo "To create another links: ln -s ${PWD}/${script} ${bin_dir}/foo.sh"

type systemctl > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
	[ ! -d "${systemd_conf_dir}" ] && mkdir ${systemd_conf_dir}
	for script in *.service; do
		if [ ! -f ${systemd_conf_dir}/${script} ];then
			# in order to "enable" service the file have to be copied, not symlinked
			cp ${PWD}/${script} ${systemd_conf_dir}
			echo "${script} copied"
			echo "enable it with :"
			echo "systemctl --user daemon-reload"
			echo "systemctl --user enable" ${script}
			echo "sudo loginctl enable-linger ${USER}"
		fi
	done
else
	echo "Systemd isn't available on this system. Startup files will not be installed"
fi
