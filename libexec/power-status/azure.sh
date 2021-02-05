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

status=$(
  az vm show \
    --resource-group  "$azure_resource_group" \
    --name "$azure_name" \
    --query "[powerState]" \
    --show-details \
    --output tsv
)

# For reference on azure's states
# https://docs.microsoft.com/en-us/azure/virtual-machines/states-lifecycle
case "$status" in
    "VM starting")
        echo 'PENDING'
        exit 0
        ;;
    "VM running")
        echo ON
        exit 0
        ;;
    "VM deallocating")
        echo STOPPING
        exit 123
        ;;
    # Azure's deallocated state is when the machine is (*mostly) not charged for
    # * Charges apply for the disk and os
    "VM deallocated")
        echo OFF
        exit 123
        ;;
    # Asure charges for "stopped"/"stopping" machines. These states should not
    # be exposed directly to the user. Instead the machine is more "sleeping"
    "VM stopping")
        echo "SLEEPING"
        exit 124
        ;;
    "VM stopped")
        echo "SLEEPING"
        exit 124
        ;;
    *)
        echo "Unknown status: ${status}" >&2
        exit 1
        ;;
esac
