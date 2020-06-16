#!/bin/bash
if [[ -z "$IP" ]]; then
    echo "The IP for node '$name' has not been set!" >&2
    exit 1
fi
ping -c 1 $IP
