#!/bin/sh

name=$(basename $0)
bin_dir="${HOME}/bin"

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

