#!/bin/bash

power_off_sync() {
    local retval

    if ! is_powered_off ; then
        "${SCRIPT_ROOT:-.}"/power-off/aws.sh >/dev/null
        retval=$?
        if [ ${retval} -ne 0 ] ; then
            return ${retval}
        fi
        sleep 5
    fi
    while ! is_powered_off ; do
        sleep 5
    done
}

is_powered_off() {
    local status
    status=$( "${SCRIPT_ROOT:-.}"/power-status/aws.sh )
    case "${status}" in
        OFF)
            # We're good to go.
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    power_off_sync
fi
