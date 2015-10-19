#!/bin/bash
scriptname="$(basename $0)"

lockdir="${XDG_RUNTIME_DIR:-${HOME}/.local/var}/${scriptname}.lock"
pidfile="${lockdir}/PID"
if mkdir ${lockdir} &> /dev/null; then
    trap "rm -rf ${lockdir}" EXIT SIGHUP SIGINT SIGQUIT SIGTERM
    echo "$$" > ${pidfile}
else
    otherpid=$(cat ${pidfile} 2>/dev/null)
    othercmd=$(ps --no-headers --format command --pid ${otherpid} 2>/dev/null)
    if [[ "${othercmd}" =~ .*${scriptname}.* ]]; then
        if [ $(ps --no-headers -C ${scriptname} | wc -l) -ge 10 ]; then
            echo "too many ${scriptname} processes waiting for lock"
            exit 1
        fi
        sleep 1
    else
        rm -rf ${lockdir}
    fi
    exec "$0" "$@"
fi

# Set secure permissions on created directories and files
umask 077

queuedir=${HOME}/.local/var/spool/msmtpqueue
mkdir -p $queuedir || exit 1
cd $queuedir || exit 1

if ! ls *.msmtp >/dev/null 2>/dev/null; then
    echo "No mails in $queuedir"
    exit 0
fi

msmtpargs=""
while getopts m: opt; do
    case $opt in
        m)
        msmtpargs="$msmtpargs -mmin +$OPTARG"
    esac
done
shift $(($OPTIND-1))

# process all mails
failcount=0
find $queuedir -type f -name "*.msmtp" $msmtpargs | while read file; do
    echo "*** Sending $file to $(perl -lne 'print $1 if $. == 1 and /-- (.*)$/' $file) ..."
    if perl -ne 'print if $. > 1' $file | msmtp $(head -1 $file) $@; then
        rm -f $file
        echo "$file sent successfully"
    else
        echo "FAILURE"
        failcount=$(($failcount+1))
    fi
done

exit $failcount
