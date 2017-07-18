#!/bin/bash
scriptname="$(basename "${BASH_SOURCE[0]}")"
rundir="${XDG_RUNTIME_DIR:-${HOME}/.local/var/run}/${scriptname}"
pidfile="${rundir}/PID"
cleanup () {
    rm -f "${pidfile}"
    flock -u 200
}
mkdir -p "${rundir}"
exec 200>"${pidfile}"
if ! flock -n 200 || ! echo "$$" > "${pidfile}"; then
    echo "another instance of the ${scriptname} is currently running..." >&2
    exit 1
fi
trap cleanup EXIT HUP INT QUIT TERM

# Set secure permissions on created directories and files
umask 077

queuedir="${HOME}/.local/var/spool/msmtpqueue"
mkdir -p "${queuedir}"
cd "${queuedir}" || exit 1

if ! find "${queuedir}" -name '*.msmtp' | read -r; then
    echo "No messages in ${queuedir}"
    exit 0
fi

msmtpargs=""
while getopts m: opt; do
    case "${opt}" in
        m)
        msmtpargs="${msmtpargs} -mmin +$OPTARG"
    esac
done
shift "$((OPTIND-1))"

# process all mails
failcount=0
while read -r file; do
    echo "*** Sending ${file} to $(perl -lne 'print $1 if $. == 1 and /-- (.*)$/' "${file}") ..."
    if tail -n +2 "${file}" | msmtp $(head -1 "${file}") "$@"; then
        rm -f "${file}"
        echo "${file} sent successfully"
    else
        echo "FAILURE"
        failcount="$((failcount+1))"
    fi
done < <(find "${queuedir}" -name '*.msmtp' ${msmtpargs})

pkill -RTMIN+4 i3blocks

exit "${failcount}"
