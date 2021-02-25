#!/bin/bash -le
#
# Docker entrypoint script
#

# set timezone
if [ ! -z "${TZ}" -a -e "/usr/share/zoneinfo/${TZ}" ]; then
	cp /usr/share/zoneinfo/${TZ} /etc/localtime
else
	cp /usr/share/zoneinfo/UTC /etc/localtime
fi

# run the comamnd and its arguments
exec "$@"
