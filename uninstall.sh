#!/bin/sh
# Remove link, config file and systemd file
# created by install.sh and tunnel.sh
#
# This script DOES NOT delete others scripts
# installed by install.sh

bin_dir="${HOME}/bin"
systemd_conf_dir="${HOME}/.config/systemd/user"
config_dir="${HOME}/.config"

# require one argument: file to remove
remove_if_exist() {
	if [ -f $1 ]; then
		rm $1
		echo "file $1 removed"
	else
		echo "file not found: $1"
	fi

}

if [ $# -eq 0 ]; then
	echo "Use: ./$0 script_to_be_removed"
	echo "eg: ./$0 foo.sh bar.sh"
else
	for script in $*; do
		remove_if_exist ${bin_dir}/${script}
		remove_if_exist ${config_dir}/${script}.conf

		systemctl --version > /dev/null 2>&1
		if [ $? ]; then
			base_script=$(echo "${script}" | cut -f1 -d '.')
			remove_if_exist ${systemd_conf_dir}/${base_script}.service
		fi

	done
fi
