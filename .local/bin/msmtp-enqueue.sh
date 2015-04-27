#!/bin/bash
umask 077

tmpdir=${HOME}/.local/var/tmp
mkdir -p $tmpdir || exit 1

queuedir=${HOME}/.local/var/spool/msmtpqueue
mkdir -p $queuedir || exit 1

tmpfile=$(mktemp --tmpdir="$tmpdir")
echo "$@" > "$tmpfile" || exit 1
cat >> "$tmpfile" || exit 1

# Create new unique filenames of the form
# ccyy-mm-dd-hh.mm.ss-pid[-x].msmtp
prefix=$(date +%Y-%m-%d-%H.%M.%S)-$$
i=
while ! ln "$tmpfile" "$queuedir/${prefix}${i}.msmtp"; do
    i=$(($i-1))
    if [ $i -lt -20 ]; then
        echo "problem creating link in queue dir."
        exit 1
    fi
done

rm $tmpfile

exit 0
