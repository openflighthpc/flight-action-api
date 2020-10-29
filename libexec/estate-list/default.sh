#!/bin/bash

# Get the last line from the show output
bash "$SCRIPT_ROOT"/estate-show/default.sh "$@" | tail -n1
