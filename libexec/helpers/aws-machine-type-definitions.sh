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

# Load the basic definitions
source "${SCRIPT_ROOT:-.}"/helpers/basic-machine-type-definitions.sh

# A map from generic machine types to the equivalent AWS EC2 instance type.
#
# NOTE: If changing this map also change the types listed in the estate
# metadata files.
MACHINE_TYPE_MAP=(
  [general-small]=t3.medium
  [general-medium]=t3.xlarge
  [general-large]=t3.2xlarge

  [compute-small]=c5.large
  [compute-medium]=c5.xlarge
  [compute-large]=c5.2xlarge

  [gpu-small]=p3.2xlarge
  [gpu-medium]=p3.8xlarge
  [gpu-large]=p3.16xlarge

  [mem-small]=r5.large
  [mem-medium]=r5.xlarge
  [mem-large]=r5.2xlarge
)
define_reverse_machine_type_map
unset -f define_reverse_machine_type_map
