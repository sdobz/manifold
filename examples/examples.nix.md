<flake description='examples demonstrating manifold features'  />


# Examples



set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

buildExample() {
    cd "$1"
    local exampleName="$(basename $1)"
    local manifold="$(dirname $1)/../manifold"
    
    cp "$("$manifold" runtime $exampleName.nix.md)" "$exampleName.nix.md.nix"
    chmod u+rw "$exampleName.nix.md.nix"
    "$manifold" fix "$exampleName.nix.md"
}

if [ -z "${1+xxx}" ]; then
    export -f buildExample
    find "$SCRIPT_DIR/" -maxdepth 1 -mindepth 1 -type d -exec bash -c 'buildExample "{}"' \;
else
    buildExample "$SCRIPT_DIR/$1"
fi
