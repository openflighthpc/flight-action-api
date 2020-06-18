#!/bin/bash

cat >&2 <<EOF
The default script for ${command} is not supported.  Specify an appropriate rank
for ${name}.
EOF
exit 1
