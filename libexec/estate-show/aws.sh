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

if [[ -z "${ec2_id}" ]]; then
    echo "The ec2_id for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${aws_region}" ]]; then
    echo "The aws_region for node '$name' has not been set!" >&2
    exit 1
fi

source "${SCRIPT_ROOT:-.}"/estate-change/machine-type-definitions.sh

aws_instance_type=$(
aws ec2 describe-instance-attribute \
  --attribute instanceType \
  --query InstanceType.Value \
  --instance-id "$ec2_id" \
  --region "$aws_region"
)

exit_code=$?

if [ ${exit_code} -eq 0 ] ; then
    # Remove the surrounding quotes.
    aws_instance_type="${aws_instance_type%\"}"
    aws_instance_type="${aws_instance_type#\"}"

    machine_type="${REVERSE_MACHINE_TYPE_MAP[$aws_instance_type]}"
    if [ "${machine_type}" == "" ]; then
        echo "unknown"
    else
        echo "${machine_type}"
    fi
else
    # Standard error from the `aws` call should be enough to debug this.
    :
fi

exit ${exit_code}

