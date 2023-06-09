set -o pipefail

if [ -z "${MD_NIX+xxx}" ] || [ -z "${CLI_SH+xxx}" ]; then
    echo "MD_NIX, CLI_SH must be set to absolute paths to those files" >&2
    exit 1
fi

sub_build() { # <source.md>      - Create a nix derivation that defines a flake for the runtime
    local sourceText="$(realpath "$1")"
    shift
    local runtimeName="$(basename "$sourceText").nix"
    nix-build \
        --impure \
        --no-out-link \
        --expr "\
            let md = import \"$MD_NIX\"; \
                pkgs = import <nixpkgs> {}; in \
            pkgs.writeText \"$runtimeName\" (md.dumpRuntime \"$RUNTIME_NIX\" \"$sourceText\")" \
            "$@"
}

sub_evaluate() { # <source.md>    - Print path to evaluated nix
    local sourceText="$(realpath "$1")"
    shift
    local runtimeName="$(basename "$sourceText").nix"
    local evaluationName="$runtimeName.md"
    nix-build \
        --impure \
        --no-out-link \
        --expr "\
            let md = import \"$MD_NIX\"; \
                pkgs = import <nixpkgs> {}; \
                runtimeNix = pkgs.writeText \"$runtimeName\" (md.dumpRuntime \"$RUNTIME_NIX\" \"$sourceText\"); in \
            pkgs.writeText \"$evaluationName\" (import runtimeNix {}).out" \
            "$@"
}

sub_diff() { # <source.md>        - Print the difference between source and evaluated texts
    local sourceText="$(realpath "$1")"
    shift
    local evalText="$(sub_evaluate "$sourceText" "$@")"
    diff "$sourceText" "$evalText"
}

sub_fix() { # <source.md>         - Replace the source markdown with its fixed variant
    local sourceText="$(realpath "$1")"
    shift
    local evalText="$(sub_evaluate "$sourceText" "$@")"
    cp "$evalText" "$sourceText"
}

sub_watch() { # <src.md> <dst.md> - Whenever src changes evaluate into dst
    local sourceText="$(realpath "$1")"
    shift
    local destinationText="$(realpath "$1")"
    shift
        
    cp "$(sub_evaluate "$sourceText")" "$destinationText"
    chmod u+rw "$destinationText"
    while inotifywait -e modify "$sourceText"; do
        cp "$(sub_evaluate "$sourceText")" "$destinationText"
    done
}

sub_eval-nix() { # "expr"         - Import markdown and run command
    local cmd="$1"
    shift
    nix eval \
        --impure \
        --expr "with import \"$MD_NIX\"; $cmd" \
        "$@"
}

sub_ast() { # <source.md>         - Dump the AST for this markdown file
    local sourceText="$(realpath "$1")"
    sub_evalNix "dumpAst \"${sourceText}\"" --json
}

sub_cloc() { #                    - Dump how many lines of code in bootstrap files
    cloc "$CLI_SH" "$MD_NIX" "$RUNTIME_NIX"
}


sub_help() { #                    - Output subcommands
    echo "Usage: nixmd <subcommand> [options]"
    echo "Subcommands:"
    grep "^sub_" "$CLI_SH" | sed 's/sub_\([a-z\-]*\).*#\(.*\)/  \1\2/g'
    echo ""
}

consume_subcommand() {
    subcommand="${1:-}"
    shift
    case $subcommand in
        "" | "-h" | "--help")
            sub_help
            ;;
        *)
            shift
            sub_${subcommand} "$@"
            if [ $? = 127 ]; then
                echo "Error: '$subcommand' is not a known subcommand." >&2
                echo "       Run 'nixmd help' for a list of known subcommands." >&2
                exit 1
            fi
            ;;
    esac
}

consume_subcommand "$@"