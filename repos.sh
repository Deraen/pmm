#!/bin/bash
# Author: Juho Teperi <juho.teperi@iki.fi>

# NOTE: Doesn't support deb-src

declare -A SOURCE_FILES
OPS=0
SOURCESDIR="/etc/apt/sources.list.d"

confirm() {
        read -r -p "$1 [Y/n] " yes
        yes=${yes,,} # tolower
        [[ $yes =~ ^(yes|y| ) ]]
}

changed() {
        if [[ ! -f $1 ]]; then return 0; fi

        local old=($(md5sum $1))
        local new=($(echo -e "$2" | md5sum))
        # Indexing array by the name only, returns the first part, in this case the hash
        [[ $new != $old ]]
}

saveRepo() {
        local filename=$SOURCESDIR/$1
        local content="$2"

        SOURCE_FILES["$filename"]=1

        if changed $filename "$content"; then
                echo "$(basename $filename) changed or added"
                echo -e $content | sudo tee $filename > /dev/null
                OPS=$((OPS + 1))
        fi
}

ppa() {
        # node.js -> node_js
        local ppaname=${2//\./_}

        saveRepo $1-$ppaname-$3.list "deb http://ppa.launchpad.net/$1/$2/ubuntu $3 main"
}

repo() {
        saveRepo $1.list "$2"
}

clearRepos() {
        local extras=""
        for file in $SOURCESDIR/*.list; do
                if [[ -z ${SOURCE_FILES["$file"]} ]]; then
                        echo "Found extra repo? $(basename $file)"
                        extras="$extras $file"
                fi
        done

        if [[ $extras ]] && confirm "Remove extras"; then
                sudo rm $extras
                OPS=$((OPS + 1))
        fi

        if [[ $OPS -gt 0 ]] && confirm "PPAs/repos changed, run getkeys?"; then
                sudo launchpad-getkeys

                if confirm "Did keys change, run update?"; then
                        sudo apt-get update
                fi
        fi
}