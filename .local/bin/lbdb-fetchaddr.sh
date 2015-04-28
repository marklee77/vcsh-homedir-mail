#!/bin/bash
fetchaddr=/usr/lib/lbdb/fetchaddr
emailfile="${HOME}/.lbdb/m_inmail.list"

mkdir -p $(dirname $emailfile)
touch $emailfile

$fetchaddr | perl -ne 's/^[^\t]+\t\K/' | while IFS=$'\t' read addr name date; do
    # lowercase addr
    addr=${addr,,}

    # quote name if it contains a ",", but don't double quote
    [[ "$name" =~ ^[^\"].*,.*[^\"]$ ]] && name="\"$name\""

    datestamp=$(date -d "$date" +%s) || echo -e "DATESTAMP: $addr\t$name\t$date"

    prevdate=$(perl -lane "print \"\$F[-2] \$F[-1]\" if \$F[0] eq '$addr'" \
               $emailfile | tail -1)
    prevstamp=0
    [ -n "$prevdate" ] && (prevstamp=$(date -d "$prevdate" +%s) || echo -e "PREVDATESTAMP: $addr\t$name\t$date")
    
    # if current is newer then delete old from file and replace
    if [ $datestamp -gt $prevstamp ]; then
        perl -i -ane "print unless \$F[0] eq '$addr'" $emailfile
        echo -e "$addr\t$name\t$date" >> $emailfile
    fi

done
