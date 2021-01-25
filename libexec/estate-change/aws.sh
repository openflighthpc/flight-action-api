#!/bin/bash
#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of Flight Action API.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Action API is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Action API. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Action API, please visit:
# https://github.com/openflighthpc/flight-action-api
#===============================================================================

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

source "${SCRIPT_ROOT:-.}"/helpers/aws-machine-type-definitions.sh

# Configures the sync helper library
export SYNC_STATUS_SCRIPT="${SCRIPT_ROOT:-.}"/power-status/aws.sh
export SYNC_POWER_ON_SCRIPT="${SCRIPT_ROOT:-.}"/power-on/aws.sh
export SYNC_POWER_OFF_SCRIPT="${SCRIPT_ROOT:-.}"/power-off/aws.sh

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
    local initial_status
    local retval
    local cur_ec2_type
    local machine_type
    local new_ec2_type

    machine_type="$1"
    validate_machine_type "${machine_type}"
    new_ec2_type="${MACHINE_TYPE_MAP[$1]}"
    cur_ec2_type=$( current_instance_type )

    if [ "${cur_ec2_type}" == "${new_ec2_type}" ] ; then
        echo "Machine type already ${machine_type}"
        exit 0
    fi

    initial_status=$( "${SCRIPT_ROOT:-.}"/power-status/aws.sh )
    if [ "${initial_status}" != "OFF" ] ; then
        echo "Powering off..."
        timeout 2m "${SCRIPT_ROOT:-.}"/helpers/power-off-sync.sh
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

    echo "Changing machine type..."
    change_instance_type "${new_ec2_type}" >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        # Standard error already printed should be sufficient.
        exit ${retval}
    fi
    echo "OK"

    case "$initial_status" in
        PENDING | ON )
            echo "Powering on..."
            timeout 5m "${SCRIPT_ROOT:-.}"/helpers/power-on-sync.sh
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
