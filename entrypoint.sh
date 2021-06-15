#!/bin/sh
set -e

# shellcheck disable=SC3057
if [ "${1:0:1}" = '-' ]; then
	set -- speedtest-cli "$@"
fi

exec "$@"
