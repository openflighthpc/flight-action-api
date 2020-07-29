#!/bin/bash
if [[ -z "$IP" ]]; then
    echo "The IP for node '$name' has not been set!" >&2
    exit 1
fi

sleep 5
echo "Powering off..."
sleep 5
echo "OK"

echo "Changing machine type..."
sleep 10
echo "OK"

echo "Powering on..."
sleep 15
echo "OK"
