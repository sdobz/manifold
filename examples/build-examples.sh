#!/usr/bin/env bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

buildExample() {
    cd "$1"
    local exampleName="$(basename $1)"
    local nixmd="$(dirname $1)/.."
    
    cp "$($nixmd/nixmd-build $exampleName.md --no-link)" $exampleName.md.nix
    cp "$(nixmd-run $exampleName.md.nix --no-link)" $exampleName.md.nix.md
}

export -f buildExample
find "$SCRIPT_DIR/" -maxdepth 1 -mindepth 1 -type d -exec bash -c 'buildExample "{}"' \;
