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
    echo "The new machine type has not been given!" >&2
    exit 1
fi

declare -A TYPE_MAP
# NOTE: If changing this map also change the types listed in the metadata
# description.
TYPE_MAP=(
  [general-small]=t2.small
  [general-large]=t2.large
  [compute-2C-3.75GB]=c4.large
  [compute-8C-15GB]=c4.2xlarge
  [gpu-1GPU-8C-61GB]=p3.2xlarge
  [gpu-4GPU-32C-244GB]=p3.8xlarge
)

validate_instance_type() {
    if [ "${TYPE_MAP[${1}]}" == "" ]; then
        echo -e "Unknown machine type ${1}.  Available machine types:\n" 1>&2
        sorted_keys=()
        while IFS= read -rd '' key; do
            sorted_keys+=( "$key" )
        done < <(printf '%s\0' "${!TYPE_MAP[@]}" | sort -z)
        for key in "${sorted_keys[@]}" ; do
            echo "${key}" 1>&2
        done
        exit 1
    fi
}

current_instance_type() {
    aws ec2 describe-instances \
        --instance-ids "${ec2_id}" \
        --region "${aws_region}" \
        --output text \
        --query Reservations[0].Instances[0].InstanceType

}

change_instance_type() {
    local ec2_type
    ec2_type="$1"
    aws ec2 modify-instance-attribute  \
        --output json \
        --instance-id "${ec2_id}" \
        --region "${aws_region}" \
        --instance-type "{\"Value\": \"${ec2_type}\"}"
}

main() {
    validate_instance_type "$@"
    local initial_status
    local retval
    local cur_ec2_type
    local generic_type
    local new_ec2_type

    generic_type="$1"
    new_ec2_type="${TYPE_MAP[$1]}"
    cur_ec2_type=$( current_instance_type )

    if [ "${cur_ec2_type}" == "${new_ec2_type}" ] ; then
        echo "Machine type already ${generic_type}"
        exit 0
    fi

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

    echo -n "Changing machine type..."
    change_instance_type "${new_ec2_type}" >/dev/null
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
