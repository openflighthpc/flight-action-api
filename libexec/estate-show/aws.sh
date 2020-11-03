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

aws_instance_type=$(
aws ec2 describe-instance-attribute \
  --attribute instanceType \
  --query InstanceType.Value \
  --instance-id "$ec2_id" \
  --region "$aws_region"
)

exit_code=$?

if [ ${exit_code} -eq 0 ] ; then
  machine_type=$(case "$aws_instance_type" in
  ('"t2.small"')    echo "general-small" ;;
  ('"t2.large"')    echo "general-large" ;;
  ('"c4.large"')    echo "compute-2C-3.75GB" ;;
  ('"c4.2xlarge"')  echo "compute-8C-15GB" ;;
  ('"p3.2xlarge"')  echo "gpu-1GPU-8C-61GB" ;;
  ('"p3.8xlarge"')  echo "gpu-4GPU-32C-244GB" ;;
  (*) 'unknown' ;;
  esac)

  echo "$machine_type"
else
    # Standard error from the `aws` call should be enough to debug this.
    :
fi

exit ${exit_code}

