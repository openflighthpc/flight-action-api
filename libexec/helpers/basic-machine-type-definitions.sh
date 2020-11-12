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

# Determines the machine types with a family
update_filtered_type_names_by_family() {
  # Create an array named according to $1. The family is given by $2
  local family=$1
  local machine_type
  FILTERED_TYPE_NAMES=()

  for machine_type in "${!MACHINE_TYPE_MAP[@]}" ; do
    if [[ "$machine_type" =~ "^${family}-" ]]; then
      FILTERED_TYPE_NAMES+=("$machine_type")
    fi
  done
}

# Check if the machine type is valid
validate_machine_type() {
  # Unpack args
  local new_type="$1"
  local family=$(echo "$2" | sed 's/-.*//')
  local valid=0

  # Determines if the new_type is unknown
  # NOTE: This reason maybe overridden when valid_types is generated
  if [ -z "${MACHINE_TYPE_MAP["$new_type"]}" ]; then
    valid=1
  fi

  # Loops through all the known machine types, doing the following:
  # 1. Generating the valid list of types (optionally filtered by family)
  # 2. Detects if the type is unsupported or outside the family
  local -a valid_types
  for machine_type in "${MACHINE_TYPE_NAMES[@]}" ; do
    # Filters out unsupported types
    if [ -z ${MACHINE_TYPE_MAP["$machine_type"]} ]; then
      if [ "$new_type" == "$machine_type" ]; then
        valid=2
      fi

    # Adds the type if it is within the family (or if the filter is off)
    elif [[ -z "$family" || "$machine_type" =~ ^${family}- ]]; then
      valid_types+=("$machine_type")

    # Flags the new_type as invalid due to the family filter
    elif [ "$new_type" == "$machine_type" ]; then
      valid=3
    fi
  done

  # Processes the error messages
  case "$valid" in
    1)
      cat 1>&2 <<ERROR
Unknown machine type ${new_type}. Available machine types:

$( printf '  %s\n' "${valid_types[@]}" )
ERROR
      exit 101
      ;;
    2)
      cat 1>&2 <<ERROR
This platform does not suport ${new_type}. Available machine types:

$( printf '  %s\n' "${valid_types[@]}" )
ERROR
      exit 102
      ;;
    3)
      cat 1>&2 <<ERROR
Changing the machine type family is not support on this platform.
Please select a '$family' type:

$( printf '  %s\n' "${valid_types[@]}" )
ERROR
      exit 103
      ;;
  esac
}
