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

# Error if the resource group has not been given
if [[ -z "${azure_resource_group}" ]]; then
    echo "The azure_resource_group for node '$name' has not been set!" >&2
    exit 1
fi

# Default the azure_name to be the same as name
azure_name="${azure_name:-$name}"

if [[ -z "${1}" ]]; then
    echo "The new machine type has not been given!" >&2
    exit 1
fi

source "${SCRIPT_ROOT:-.}"/helpers/azure-machine-type-definitions.sh

# Configures the sync helper library
export SYNC_STATUS_SCRIPT="${SCRIPT_ROOT:-.}"/power-status/azure.sh
export SYNC_POWER_ON_SCRIPT="${SCRIPT_ROOT:-.}"/power-on/azure.sh
export SYNC_POWER_OFF_SCRIPT="${SCRIPT_ROOT:-.}"/power-off/azure.sh

current_instance_type() {
  local output=$(
    az vm get-instance-view \
      --resource-group  "$azure_resource_group" \
      --name "$azure_name" \
      --query hardwareProfile.vmSize
  )
  local exit_code=$?

  if [ "$exit_code" -eq 0 ]; then
    output="${output%\"}"
    output="${output#\"}"
    echo "$output"
    return 0
  else
    # End the script if the current instance type can not be determined
    # Whilst "technically" `az vm resize` may still work, there is probably
    # a configuration error
    exit "$exit_code"
  fi
}

change_instance_type() {
  az vm resize \
    --resource-group  "$azure_resource_group" \
    --name "$azure_name" \
    --size "$1"
}

main() {
    local initial_status
    local retval
    local cur_machine_type
    local machine_type
    local new_machine_type

    machine_type="$1"
    validate_machine_type "${machine_type}"
    new_machine_type="${MACHINE_TYPE_MAP[$1]}"
    cur_machine_type=$( current_instance_type )

    if [ "${cur_machine_type}" == "${new_machine_type}" ] ; then
        echo "Machine type already ${machine_type}"
        exit 0
    fi

    initial_status=$( "${SCRIPT_ROOT:-.}"/power-status/azure.sh )
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
    change_instance_type "${new_machine_type}" >/dev/null
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
