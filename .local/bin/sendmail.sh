#!/bin/bash
tee >(lbdb-fetchaddr.sh) | msmtp-enqueue.sh $@
