#!/bin/bash
#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
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

# Ensures the SYNC_STATUS_SCRIPT has been defined!
__sync_run_status_script() {
  if [ -x "$SYNC_STATUS_SCRIPT" ]; then
    $SYNC_STATUS_SCRIPT
  else
    echo 'SYNC_STATUS_SCRIPT is not executable!' >&2
    return 126
  fi
}

# Ensures the SYNC_POWER_ON_SCRIPT has been defined!
__sync_run_power_on_script() {
  if [ -x "$SYNC_POWER_ON_SCRIPT" ]; then
    $SYNC_POWER_ON_SCRIPT
  else
    echo 'SYNC_POWER_ON_SCRIPT is not executable!' >&2
    return 126
  fi
}

# Ensures the SYNC_POWER_OFF_SCRIPT has been defined!
__sync_run_power_off_script() {
  if [ -x "$SYNC_POWER_OFF_SCRIPT" ]; then
    $SYNC_POWER_OFF_SCRIPT
  else
    echo 'SYNC_POWER_OFF_SCRIPT is not executable!' >&2
    return 126
  fi
}

# Checks if the SYNC_STATUS_SCRIPT exits the given code
# Returns 0 if true, else 1
is_sync_status() {
  local status

  # Ensure a state has been given
  if [ -z "$1" ]; then
    echo "No state given!" >&2
    return 1
  fi

  # Runs the script and compares STDOUT against the state
  status=$(__sync_run_status_script)
  case "${status}" in
    "$1")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Loops until the SYNC_STATUS_SCRIPT exits ON and SSH becomes available
# NOTE: Will attempt to power on the machine if required
power_on_sync() {
  local retval

  # Attempts to power the node on if required
  if ! is_sync_status "ON" ; then
    __sync_run_power_on_script >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        return ${retval}
    fi
    sleep 5
  fi

  # Loops until the machine is ON
  while ! is_sync_status "ON" ; do
    sleep 5
  done

  # Wait until the machine responds to SSH/ port 22
  while ! nc -zw 1 "${name}" 22 ; do
      sleep 5
  done
}

# Loops until the SYNC_STATUS_SCRIPT exits OFF
# NOTE: Will attempt to power off the machine if required
power_off_sync() {
  local retval

  # Attempts to power the node off if required
  if ! is_sync_status "OFF" ; then
    __sync_run_power_off_script >/dev/null
    retval=$?
    if [ ${retval} -ne 0 ] ; then
        return ${retval}
    fi
    sleep 5
  fi

  # Loops until the machine is OFF
  while ! is_sync_status "OFF" ; do
    sleep 5
  done
}
