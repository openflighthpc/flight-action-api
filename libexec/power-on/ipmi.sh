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

# Ensures the ipmi username and password is provided
if [[ -z "${ipmi_username}" ]]; then
    echo "The ipmi_username for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${ipmi_password}" ]]; then
    echo "The ipmi_password for node '$name' has not been set!" >&2
    exit 1
fi

# Allows the ipmi host to be overridden
ipmi_host="${ipmi_host:-"$name.bmc"}"

ipmitool -U "$ipmi_username" -P "$ipmi_password" -H "$ipmi_host" -I lanplus \
  chassis power on >/dev/null

exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  echo OK
else
  # Standard error form ipmi should be enough here
  :
fi

exit "$exit_code"
