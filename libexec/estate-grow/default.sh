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

# Sources the configuration script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$DIR"/keys.conf

# Ensure all the required keys are set
set -e
missing=
if [ -z "$flight_ESTATE_cluster" ]; then
  missing="flight_ESTATE_cluster"
elif [ -z "$flight_ESTATE_slack_key" ]; then
  missing="flight_ESTATE_slack_key"
elif [ -z "$flight_ESTATE_slack_channels" ]; then
  missing="flight_ESTATE_slack_channels"
fi

if [ -n "$missing" ]; then
  cat >&2 <<ERROR
Error: Could not complete the request due to an internal configuration error ($missing).
Please contact your system administrator for further assistance.
ERROR
  exit 1
fi

# Sets the default action
if [[ -z "$__flight_ESTATE_action" ]]; then
  __flight_ESTATE_action='Grow'
fi

# Sets the types
declare -a types=(
 compute-2C-3.75GB compute-8C-15GB general-large general-small gpu-1GPU-8C-61GB gpu-4GPU-32C-244GB
)

# Unpacks the channels
IFS=':' read -r -a channels <<< "$flight_ESTATE_slack_channels"

# Unpacks the arguments
machine_type="$1"
number="$2"

# Ensures the type is valid
found=''
for current in ${types[@]}; do
  if [[ "$current" == "$machine_type" ]]; then
    found="$current"
    break
  fi
done
if [ -z "$found" ]; then
  cat >&2 <<ERROR
Unknown machine type $machine_type.  Available machine types:
$(echo ${types[@]} | xargs -n1)
ERROR
  exit 1
fi

# Ensures the number is indeed a number
if [[ ! "$number" =~ ^[0-9]+$ ]]; then
  cat >&2 <<ERROR
Error: Can not continue as NUMBER is not a whole number.
ERROR
  exit 1
fi

# Creates the JSON payload for slack
for channel in "${channels[@]}"; do
  output=$(curl -H 'Content-Type: application/json; charset=UTF-8' \
                -H "Authorization: Bearer $flight_ESTATE_slack_key" \
                -d @- \
                "https://slack.com/api/chat.postMessage" \
                2>/dev/null << PAYLOAD
{
  "channel": "$channel",
  "as_user": true,
  "text": "Received a \`flight-estate\` modification request!",
  "attachments": [
    {
      "text": "*User (Unauthenticated):* $request_username ($request_uid)\n*Cluster*: $flight_ESTATE_cluster\n*Action*: $__flight_ESTATE_action\n*Machine Type*: $machine_type\n*Number*: $number"
    }
  ]
}
PAYLOAD
)
  if echo "$output" | grep '"ok":false' >/dev/null; then
    error=$(echo "$output" | sed 's/.*"error":"\([^"]*\)".*/\1/g')
    cat >&2 <<ERROR
Error: An unexpected error has occurred ($error)!
Please contact your system administrator for further assistance.
ERROR
    exit 1
  fi
done

# Notifies the user the request is complete
echo Your request has been received and will be processed shortly.
exit 0
