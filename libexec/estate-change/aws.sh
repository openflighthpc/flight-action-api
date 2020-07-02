#!/bin/bash

if [[ -z "${ec2_id}" ]]; then
    echo "The ec2_id for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${aws_region}" ]]; then
    echo "The aws_region for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${1}" ]]; then
    echo "The new instance type has not been given!" >&2
    exit 1
fi

output=$(
aws ec2 modify-instance-attribute  \
    --output json \
    --instance-id "${ec2_id}" \
    --region "${aws_region}" \
    --instance-type "{\"Value\": \"${1}\"}"
)

exit_code=$?

if [ ${exit_code} -eq 0 ] ; then
    echo OK
else
    # Standard error from the `aws` call should be enough to debug this.
    :
fi

exit ${exit_code}
