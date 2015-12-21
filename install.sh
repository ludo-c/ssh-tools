#!/bin/sh
# usage :
# install_script.sh [links names]
# Can be used without arguments, create only tunnel.sh
# with one or more arguments, create links with thoses names

name=$(basename $0)
bin_dir="${HOME}/bin"
systemd_conf_dir="${HOME}/.config/systemd/user"
origin="tunnel.sh"

[ ! -d "${bin_dir}" ] && mkdir -p ${bin_dir}

if [ $# -eq 0 ]; then
	if [ ! -f ${bin_dir}/${origin} ]; then
		ln -s ${PWD}/${origin} ${bin_dir}/
		${bin_dir}/${origin} create config file
	else
		echo "${bin_dir}/${origin}: file exists"
	fi
else
	for script in $*
	do
		# link only files that are not already linked
		if [ ! -f ${bin_dir}/${script} ]; then
			ln -s ${PWD}/${origin} ${bin_dir}/${script}
			echo "link created for ${script}"
			${bin_dir}/${script} create config file
		fi
	done
fi
