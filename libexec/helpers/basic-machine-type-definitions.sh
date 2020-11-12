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

# Define all known machine types
# NOTE: Not all of them will be defined on every platform
MACHINE_TYPE_NAMES=(
  general-small
  general-medium
  general-large

  compute-small
  compute-medium
  compute-large

  gpu-small
  gpu-medium
  gpu-large

  mem-small
  mem-medium
  mem-large
)

# Define the empty mapping variables
# NOTE: These maps should not contain any types not defined above
#       In case of conflict, the above list should be considered definitive
declare -A MACHINE_TYPE_MAP
declare -A REVERSE_MACHINE_TYPE_MAP

# Helper method for generating the reverse mapping variable
# NOTE: The method is commonly undefined after being called
define_reverse_machine_type_map() {
  local machine_type
  local instance_type

  for machine_type in "${!MACHINE_TYPE_MAP[@]}" ; do
      instance_type="${MACHINE_TYPE_MAP[${machine_type}]}"
      REVERSE_MACHINE_TYPE_MAP[$instance_type]="${machine_type}"
  done
}

# Check if the machine type is valid
validate_machine_type() {
    if [ "${MACHINE_TYPE_MAP[${1}]}" == "" ]; then
        cat 1>&2 <<ERROR
Unknown machine type ${1}.  Available machine types:

$( printf '  %s\n' "${MACHINE_TYPE_NAMES[@]}" )
ERROR
        exit 1
    fi
}
