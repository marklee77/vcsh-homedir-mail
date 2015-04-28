#!/bin/bash
fetchaddr=/usr/lib/lbdb/fetchaddr
emailfile="${HOME}/.lbdb/m_inmail.list"

mkdir -p $(dirname $emailfile)
touch $emailfile

$fetchaddr | while IFS=$'\t' read -a fields; do

    addr=${fields[0]//\'}
    name=${fields[@]:1:$((${#fields[@]}-2))}
    date=${fields[-1]}

    # lowercase addr
    addr=${addr,,}

    # fix encoding in name
    encoding=$(file -bi - <<< "$name" | perl -ne 'print $1 if /charset=(.*)/')
    name=$(iconv -f $encoding -t utf-8 <<< "$name")

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
