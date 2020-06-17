#!/bin/bash

if [[ -z "${ec2_id}" ]]; then
    echo "The ec2_id for node '$name' has not been set!" >&2
    exit 1
fi
if [[ -z "${aws_region}" ]]; then
    echo "The aws_region for node '$name' has not been set!" >&2
    exit 1
fi

status=$(aws ec2 describe-instances \
                 --instance-ids "${ec2_id}" \
                 --region "${aws_region}" \
                 --query Reservations[0].Instances[0].State.Name
                 )

case "$status" in
    "running")
        echo ON
        exit 0
        ;;
    "stopped")
        echo OFF
        exit 123
        ;;
    *)
        exit 1
        ;;
esac
