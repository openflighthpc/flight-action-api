#!/bin/bash

# Get the last line from the show output
bash "$SCRIPT_ROOT"/estate-show/aws.sh "$@" | tail -n1
