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

current_instance_type() {
  az vm get-instance-view \
    --resource-group  "$azure_resource_group" \
    --name "$azure_name" \
    --query hardwareProfile.vmSize
}

change_instance_type() {
  az vm resize \
    --resource-group  "$azure_resource_group" \
    --name "$azure_name" \
    --size "$1"
}

main() {
    local retval
    local machine_type
    local cur_azure_type
    local new_azure_type

    machine_type="$1"
    validate_machine_type "${machine_type}"
    new_azure_type="${MACHINE_TYPE_MAP[$1]}"
    cur_azure_type=$( current_instance_type )
    cur_azure_type="${cur_azure_type%\"}"
    cur_azure_type="${cur_azure_type#\"}"

    if [ "${cur_azure_type}" == "${new_azure_type}" ] ; then
        echo "Machine type already ${machine_type}"
        exit 0
    fi

    echo "Changing machine type..."
    change_instance_type "${new_azure_type}" >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        # Standard error already printed should be sufficient.
        exit ${retval}
    fi
    echo "OK"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
