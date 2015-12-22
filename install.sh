#!/bin/sh
# usage :
# install_script.sh [links names]
# Can be used without arguments, create only tunnel.sh
# with one or more arguments, create links with thoses names

name=$(basename $0)
bin_dir="${HOME}/bin"
systemd_conf_dir="${HOME}/.config/systemd/user"
origin="tunnel.sh"
print_systemd_msg=0
systemd=0

[ ! -d "${bin_dir}" ] && mkdir -p ${bin_dir}
# Is systemd installed here
systemctl --version > /dev/null 2> /dev/null
if [ $? -eq 0 ]; then
	[ ! -d "${systemd_conf_dir}" ] && mkdir -p ${systemd_conf_dir}
	systemd=1
fi

create_symlink() {
	script=$1
	# link only files that are not already linked
	if [ ! -f ${bin_dir}/${script} ]; then
		ln -s ${PWD}/${origin} ${bin_dir}/${script}
		echo "link created for ${bin_dir}/${script}"
		${bin_dir}/${script} create config file
	fi
}

create_systemd_service() {
	script=$1
	base_script=$(echo "${script}" | cut -f1 -d '.')
	if [ ${systemd} -eq 1 ] && [ ! -f ${systemd_conf_dir}/${base_script}.service ]; then
		print_systemd_msg=1
		# remove extension
		sed -e "s@###script###@${script}@" -e "s@###user###@${USER}@" \
			tunnel.template > ${systemd_conf_dir}/${base_script}.service
	fi
}

if [ $# -eq 0 ]; then
	create_symlink ${origin}
	create_systemd_service ${origin}
else
	for script in $*
	do
		create_symlink ${script}
		create_systemd_service ${script}
	done
fi

if [ ${print_systemd_msg} -eq 1 ]; then
	echo "Enable systemd services with :"
	echo "systemctl --user daemon-reload"
	echo "systemctl --user start <script>  # start service now"
	echo "systemctl --user enable <script>  # autostart"
	echo "# If you want your services at boot time (and not when you open your session):"
	echo "sudo loginctl enable-linger ${USER}"
fi

