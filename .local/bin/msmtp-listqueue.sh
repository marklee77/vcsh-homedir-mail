#!/bin/bash
queuedir=${HOME}/.local/var/spool/msmtpqueue
mkdir -p $queuedir || exit 1

if ! ls ${queuedir}/*.msmtp >/dev/null 2>/dev/null; then
    echo "No mails in $queuedir"
    exit 0
fi

for file in ${queuedir}/*.msmtp; do
    egrep -s --colour -h '(^From:|^To:|^Subject:)' "$file"
    echo " "
done

exit 0
