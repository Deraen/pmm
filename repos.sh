#!/bin/bash
# Author: Juho Teperi <juho.teperi@iki.fi>

# NOTE: Doesn't support deb-src

declare -A SOURCE_FILES
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
        fi
}

repo() {
        local NAME=$1
        local REPO=$2
        shift
        shift

        saveRepo $NAME.list "$REPO"

        local KEYRING="$NAME"
        local KEYID
        local KEY_URL

        while [[ $# -gt 0 ]]; do
                key=$1
                case $key in
                        --keyid)
                                KEYID="$2"
                                shift
                                shift
                                ;;
                        --keyring)
                                KEYRING="$2"
                                shift
                                shift
                                ;;
                        --key-url)
                                KEY_URL="$2"
                                shift
                                shift
                                ;;
                        *)
                                echo "Unknown option: $key"
                                shift
                                ;;
                esac
        done

        local file="/etc/apt/trusted.gpg.d/$KEYRING.gpg"
        if [[ ! -f "$file" ]]; then
                if [[ ! -z $KEYID ]]; then
                        sudo gpg \
                                --no-default-keyring \
                                --keyring "$file" \
                                --keyserver hkp://keyserver.ubuntu.com:80 \
                                --recv-keys "$KEYID"
                elif [[ ! -z $KEY_URL ]]; then
                        curl -sSL "$KEY_URL" | sudo gpg \
                                --no-default-keyring \
                                --keyring "$file" \
                                --import
                fi

                if [[ ! -z $KEYID ]] || [[ ! -z $KEY_URL ]]; then
                        chmod og+r "$file"
                fi
        fi
}

ppa() {
        # node.js -> node_js
        local NAME="$1-${2//\./_}-$3"
        local REPO="deb http://ppa.launchpad.net/$1/$2/ubuntu $3 main"
        shift
        shift
        shift
        repo "$NAME" "$REPO" $@
}

updateRepos() {
        for file in $SOURCESDIR/*.list; do
                if [[ -z ${SOURCE_FILES["$file"]} ]]; then
                        if confirm "Found extra repository file $(basename $file), remove?"; then
                                rm $file
                        fi
                fi
        done

        # TODO: Clean /etc/apt/trusted.gpg.d/

        if confirm "Run update?"; then
                sudo apt update
        fi
}
