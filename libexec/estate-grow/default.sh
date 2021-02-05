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

set -e

source "${SCRIPT_ROOT:-.}"/estate-grow/keys.conf
source "${SCRIPT_ROOT:-.}"/helpers/aws-machine-type-definitions.sh

# Sets the default action.  This script is also used by the estate-shrink
# script with a different action set.
if [[ -z "$__flight_ESTATE_action" ]]; then
    __flight_ESTATE_action='Grow'
fi

validate_slack_configuration() {
    local missing
    missing=
    if [ -z "$flight_ESTATE_cluster" ]; then
        missing="flight_ESTATE_cluster"
    elif [ -z "$flight_ESTATE_slack_key" ]; then
        missing="flight_ESTATE_slack_key"
    elif [ -z "$flight_ESTATE_slack_channels" ]; then
        missing="flight_ESTATE_slack_channels"
    fi
    if [ -n "$missing" ]; then
        cat 1>&2 <<ERROR
Error: Could not complete the request due to an internal configuration error ($missing).
Please contact your system administrator for further assistance.
ERROR
        exit 1
    fi
}

# Ensures the number is indeed a number
validate_number_format() {
  if [[ ! "${1}" =~ ^[0-9]+$ ]]; then
    cat 1>&2 <<ERROR
Error:  Unrecognised number format ${1}.
ERROR
    exit 1
  fi
}

# Expects ${channel}, ${machine_type} and ${number} to be set in the calling
# scope.
#
# Sends message to ${channel}.
send_slack_message() {
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
}

main() {
  validate_slack_configuration

  local channels
  local machine_type
  local number

  machine_type="$1"
  number="$2"
  validate_machine_type "${machine_type}"
  validate_number_format "${number}"

  IFS=':' read -r -a channels <<< "$flight_ESTATE_slack_channels"
  for channel in "${channels[@]}"; do
    send_slack_message
  done

  echo Your request has been received and will be processed shortly.
  exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
