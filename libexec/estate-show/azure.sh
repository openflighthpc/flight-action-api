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
echo "${azure_name:=$name}" >/dev/null

# Source the resource mappings
source "${SCRIPT_ROOT:-.}"/helpers/azure-machine-type-definitions.sh

azure_instance_type=$(
  az vm get-instance-view \
    --resource-group  "$azure_resource_group" \
    --name "$azure_name" \
    --query hardwareProfile.vmSize
)

exit_code=$?

if [ ${exit_code} -eq 0 ] ; then
    # Remove the surrounding quotes.
    azure_instance_type="${azure_instance_type%\"}"
    azure_instance_type="${azure_instance_type#\"}"

    machine_type="${REVERSE_MACHINE_TYPE_MAP[$azure_instance_type]}"
    if [ "${machine_type}" == "" ]; then
        echo "unknown (${azure_instance_type})"
    else
        echo "${machine_type}"
    fi
else
    # Standard error from the `az` call should be enough to debug this.
    :
fi

exit ${exit_code}
