#!/usr/bin/env bash

# ./build-example.sh HelloBash
#    build one
# ./build-example.sh
#    build all

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

buildExample() {
    cd "$1"
    local exampleName="$(basename $1)"
    local nixmd="$(dirname $1)/../nixmd"
    
    cp "$("$nixmd" build $exampleName.md)" $exampleName.md.nix
    "$nixmd" fix "$exampleName.md"
}

if [ -z "${1+xxx}" ]; then
    export -f buildExample
    find "$SCRIPT_DIR/" -maxdepth 1 -mindepth 1 -type d -exec bash -c 'buildExample "{}"' \;
else
    buildExample "$SCRIPT_DIR/$1"
fi
