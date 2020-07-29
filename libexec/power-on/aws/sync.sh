#!/bin/bash

WAIT_FOR_SSH=0

power_on_sync() {
    local retval

    if ! is_powered_on ; then
        "${SCRIPT_ROOT:-.}"/power-on/aws.sh >/dev/null
        retval=$?
        if [ ${retval} -ne 0 ] ; then
            return ${retval}
        fi
        sleep 5
    fi
    while ! is_powered_on ; do
        sleep 5
    done
    if [ WAIT_FOR_SSH ] ; then
        while ! nc -zw 1 "${name}" 22 ; do
            sleep 5
        done
    fi
}

is_powered_on() {
    local status
    status=$( "${SCRIPT_ROOT:-.}"/power-status/aws.sh )
    case "${status}" in
        ON)
            # We're good to go.
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" == "--wait-for-ssh" ] ; then
        WAIT_FOR_SSH=1
    fi
    power_on_sync
fi
