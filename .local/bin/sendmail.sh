#!/bin/bash
tee >(lbdb-fetchaddr.sh) | msmtp-enqueue.sh "$@"
pkill -RTMIN+4 i3blocks
