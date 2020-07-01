#!/bin/bash

if [[ -z "${ec2_id}" ]]; then
    echo "The ec2_id for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${aws_region}" ]]; then
    echo "The aws_region for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${1}" ]]; then
    echo "The new instance type has not been given!" >&2
    exit 1
fi

change_instance_type() {
    aws ec2 modify-instance-attribute  \
        --output json \
        --instance-id "${ec2_id}" \
        --region "${aws_region}" \
        --instance-type "{\"Value\": \"${1}\"}"
}

main() {
    local initial_status
    local retval

    initial_status=$( "${SCRIPT_ROOT:-.}"/power-status/aws.sh )
    if [ "${initial_status}" != "OFF" ] ; then
        echo -n "Powering off..."
        timeout 5m "${SCRIPT_ROOT:-.}"/power-off/aws/sync.sh
        retval=$?
        if [ ${retval} -eq 124 ] ; then
            echo "Timed out waiting for node to power off" 1>&2
            exit ${retval}
        fi
        if [ ${retval} -ne 0 ] ; then
            # Standard error already printed should be sufficient.
            exit ${retval}
        fi
        echo "OK"
    fi

    echo -n "Changing instance type..."
    change_instance_type "$@" >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        # Standard error already printed should be sufficient.
        exit ${retval}
    fi
    echo "OK"

    case "$initial_status" in
        PENDING | ON )
            echo -n "Powering on..."
	    timeout 5m "${SCRIPT_ROOT:-.}"/power-on/aws/sync.sh
            retval=$?
            if [ ${retval} -eq 124 ] ; then
                echo "Timed out waiting for node to power on" 1>&2
                exit ${retval}
            fi
            if [ ${retval} -ne 0 ] ; then
                # Standard error already printed should be sufficient.
                exit ${retval}
            fi
            echo "OK"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
