#!/bin/bash
LIBEXEC="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

# Get the last line from the show output
bash "$LIBEXEC"/estate-show/aws.sh "$@" | tail -n1
