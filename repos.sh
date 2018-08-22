#!/bin/bash
# Author: Juho Teperi <juho.teperi@iki.fi>

# NOTE: Doesn't support deb-src

declare -A SOURCE_FILES
SOURCESDIR="/etc/apt/sources.list.d"

confirm() {
    local OPTIND
    local prompt="[Y/n]"
    local default="y"
    while getopts ":i" opt; do
        case $opt in
            i)
                default="n"
                prompt="[y/N]"
                ;;
        esac
    done

    shift $(($OPTIND - 1))

    read -r -p "$1 $prompt " ans
    ans=${ans,,} # tolower
    if [[ ! $ans ]]; then
        ans=$default
    fi
    [[ $ans =~ ^(yes|y) ]]
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

        if [[ -f "$file" ]] && [[ ! -s "$file" ]]; then
            # Clean empty file
            sudo rm "$file"
        fi

        if [[ ! -z $KEYID ]]; then
                # If file doesn't exist or keyring doesn't contain the key
                if [[ ! -f "$file" ]] || ! gpg --no-default-keyring --keyring "$file" --list-key "$KEYID" &> /dev/null; then
                        echo "Get key $KEYID"
                        sudo apt-key \
                                --keyring "$file" \
                                adv \
                                --keyserver hkp://keyserver.ubuntu.com:80 \
                                --recv-keys "$KEYID"
                fi
        elif [[ ! -z $KEY_URL ]]; then
                # If file doesn't exist or keyring doesn't contain any keys
                if [[ ! -f "$file" ]] || [[ $(gpg --no-default-keyring --keyring "$file" --list-keys | wc -l) == "0" ]]; then
                        echo "Download $KEY_URL"
                        curl -sSL "$KEY_URL" | sudo apt-key --keyring "$file" add -
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

        if confirm -i "Run update?"; then
                sudo apt update
        fi
}
