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
if ! flock -w 5 200 || ! echo "$$" > "${pidfile}"; then
    echo "another instance of the ${scriptname} is holding the lock..." >&2
    exit 1
fi
trap cleanup EXIT HUP INT QUIT TERM

fetchaddr=/usr/lib/lbdb/fetchaddr
emailfile="${HOME}/.lbdb/m_inmail.list"

[ -f "$1" ] && exec <"$1"

mkdir -p "$(dirname "${emailfile}")"
touch "${emailfile}"

headers="$(reformail -X from: -X to: -X cc: -X bcc: -X date:)"

encoding="$(file -bi - <<< "${headers}" | sed -nr 's/.*\scharset=(.*)/\1/p')"
headers="$(iconv -f "${encoding}" -t utf-8 <<< "${headers}" 2>/dev/null)"
msgdate="$(date -d "$(reformail -x date: <<< "$headers")" +"%Y-%m-%d %H:%M" 2>/dev/null)"

while IFS=$'\t' read -r -a fields; do

    addr="${fields[0]//\'}"
    name="${fields[*]:1:$((${#fields[*]}-2))}"
    date="${fields[-1]}"

    # lowercase addr
    addr="${addr,,}"

    [ -n "${msgdate}" ] && date="${msgdate}"

    datestamp="$(date -d "${date}" +%s)"

    prevdate="$(sed -nr "s/^${addr}\s.*\s(\S+\s+\S+)\$/\1/p" "${emailfile}" | tail -1 )"
    prevstamp=0
    [ -n "$prevdate" ] && prevstamp=$(date -d "$prevdate" +%s)

    # if current is newer then delete old from file and replace
    if [ "${datestamp}" -gt "${prevstamp}" ]; then
        sed -i "/^${addr}\s/d" "${emailfile}"
        echo -e "${addr}\t${name}\t${date}" >> "${emailfile}"
    fi

done < <("${fetchaddr}" -c utf-8 <<< "${headers}")
