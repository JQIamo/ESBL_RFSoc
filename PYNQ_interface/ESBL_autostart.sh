#!/bin/bash
. /etc/environment
for f in /etc/profile.d/*.sh; do source $f; done

python3 /home/xilinx/ESBL/parser.py
