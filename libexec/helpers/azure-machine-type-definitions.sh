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

# A map from generic machine types to the equivalent Azure instance type.
#
# NOTE: If changing this map also change the types listed in the estate
# metadata files.
declare -A MACHINE_TYPE_MAP
MACHINE_TYPE_MAP=(
  [general-small]=Standard_B2s
  #[general-medium]=
  #[general-large]=

  [compute-small]=Standard_F2s_v2
  [compute-medium]=Standard_F4s_v2
  [compute-large]=Standard_F8s_v2

  [gpu-small]=Standard_NC6s_v3
  [gpu-medium]=Standard_NC24s_v3
  # [gpu-large]=Undefined_gpu_large

  [mem-small]=Standard_E2_v4
  [mem-medium]=Standard_E4_v4
  [mem-large]=Standard_E8_v4
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
unset -f set_type_names

# A map from AWS EC2 instance type to generic machine type.
declare -A REVERSE_MACHINE_TYPE_MAP
set_reverse_map() {
    local machine_type
    local instance_type
    for machine_type in "${!MACHINE_TYPE_MAP[@]}" ; do
        instance_type="${MACHINE_TYPE_MAP[${machine_type}]}"
        REVERSE_MACHINE_TYPE_MAP[$instance_type]="${machine_type}"
    done
}
set_reverse_map
unset -f set_reverse_map

validate_machine_type() {
    if [ "${MACHINE_TYPE_MAP[${1}]}" == "" ]; then
        cat 1>&2 <<ERROR
Unknown machine type ${1}.  Available machine types:

$( printf '  %s\n' "${MACHINE_TYPE_NAMES[@]}" )
ERROR
        exit 1
    fi
}
