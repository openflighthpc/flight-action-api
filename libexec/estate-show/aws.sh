#!/bin/bash

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
  ('"t2.small"') echo "general-small" ;;
  ('"t2.large"') "general-large" ;;
  ('"c4.large"') "compute-2C-3.75GB" ;;
  ('"c4.2xlarge"') "compute-8C-15GB" ;;
  ('"p3.2xlarge"') "gpu-1GPU-8C-61GB" ;;
  ('"p3.8xlarge"') "gpu-4GPU-32C-244GB" ;;
  (*) 'unknown' ;;
  esac)

  echo "$name": "$machine_type"
else
    # Standard error from the `aws` call should be enough to debug this.
    :
fi

exit ${exit_code}

