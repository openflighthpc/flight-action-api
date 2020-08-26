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
echo "${flight_ESTATE_cluster:?The flight_ESTATE_cluster has not been set!}" >/dev/null
echo "${flight_ESTATE_slack_key:?The flight_ESTATE_slack_key has not been set!}" >/dev/null
echo "${flight_ESTATE_slack_channels:?The flight_ESTATE_slack_channels has not been set!}" >/dev/null

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
if [ "$found" ]; then
  echo "Type OK: $found"
else
  echo "Not a type: $machine_type"
  exit 1
fi

# Ensures the number is indeed a number
if [[ "$number" =~ ^[0-9]+$ ]]; then
  echo "Number OK: $number"
else
  echo "Not a number: $number" >&2
  exit 1
fi

# Creates the JSON payload for slack
for channel in "${channels[@]}"; do
  curl  -H 'Content-Type: application/json; charset=UTF-8' \
        -H "Authorization: Bearer $flight_ESTATE_slack_key" \
        -d @- \
        "https://slack.com/api/chat.postMessage" \
        << PAYLOAD
{
  "channel": "$channel",
  "as_user": true,
  "text": "Hello Slack"
}
PAYLOAD
done
