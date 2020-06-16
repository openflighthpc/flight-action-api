#!/bin/bash
if [[ -z "$IP" ]]; then
    echo "The IP for node '$name' has not been set!" >&2
    exit 1
fi
MAX=${MAX:="100"}

count=0
while [ $count -le $MAX ]
do
    ((count++))
    if ping -c 1 "$IP"; then
        exit 0
    fi
done
exit $?
