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

# A map from generic machine types to the equivalent AWS EC2 instance type.
#
# NOTE: If changing this map also change the types listed in the estate
# metadata files.
declare -A MACHINE_TYPE_MAP
MACHINE_TYPE_MAP=(
  [general-small]=t2.small
  [general-large]=t2.large
  [compute-2C-3.75GB]=c4.large
  [compute-8C-15GB]=c4.2xlarge
  [gpu-1GPU-8C-61GB]=p3.2xlarge
  [gpu-4GPU-32C-244GB]=p3.8xlarge
)

# An array of machine types.
declare -a MACHINE_TYPE_NAMES
set_type_names() {
    local key
    while IFS= read -rd '' key; do
        MACHINE_TYPE_NAMES+=( "$key" )
    done < <(printf '%s\0' "${!MACHINE_TYPE_MAP[@]}" | sort -z)
}
set_type_names

validate_machine_type() {
    if [ "${MACHINE_TYPE_MAP[${1}]}" == "" ]; then
        cat 1>&2 <<ERROR
Unknown machine type ${1}.  Available machine types:
$( printf '%s\n' "${MACHINE_TYPE_NAMES[@]}" )
ERROR
        exit 1
    fi
}
