#!/bin/bash
fetchaddr=/usr/lib/lbdb/fetchaddr
emailfile="${HOME}/.lbdb/m_inmail.list"

if [ -f "$1" ]; then
    if ! [[ $(file -bi $1) =~ ^message/rfc822\; ]]; then
        exit 0
    fi
    exec < $1    
fi

mkdir -p $(dirname $emailfile)
touch $emailfile

headers=$(reformail -X from: -X to: -X cc: -X bcc: -X date:)

msgdate=$(date -d "$(reformail -x date: <<< "$headers")" +"%Y-%m-%d %H:%M" \
          2>/dev/null)
encoding=$(file -bi - <<< "$headers" | perl -ne 'print $1 if /charset=(.*)/')
headers=$(iconv -f $encoding -t utf-8 <<< "$headers")

$fetchaddr -c utf-8 -a <<< "$headers" | while IFS=$'\t' read -a fields; do

    addr=${fields[0]//\'}
    name=${fields[@]:1:$((${#fields[@]}-2))}
    date=${fields[-1]}

    # lowercase addr
    addr=${addr,,}

    [ -n "$msgdate" ] && date=$msgdate

    datestamp=$(date -d "$date" +%s)

    prevdate=$(perl -lane "print \"\$F[-2] \$F[-1]\" if \$F[0] eq '$addr'" \
               $emailfile | tail -1)
    prevstamp=0
    [ -n "$prevdate" ] && prevstamp=$(date -d "$prevdate" +%s)
    
    # if current is newer then delete old from file and replace
    if [ $datestamp -gt $prevstamp ]; then
        perl -i -ane "print unless \$F[0] eq '$addr'" $emailfile
        echo -e "$addr\t$name\t$date" >> $emailfile
    fi

done
