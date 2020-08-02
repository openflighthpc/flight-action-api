#!/bin/bash
if [[ -z "$IP" ]]; then
    echo "The IP for node '$name' has not been set!" >&2
    exit 1
fi

sleep 2
echo "Powering off..."
sleep 2
echo "OK"

echo "Changing machine type..."
sleep 5
echo "OK"

echo "Powering on..."
sleep 5
echo "OK"
